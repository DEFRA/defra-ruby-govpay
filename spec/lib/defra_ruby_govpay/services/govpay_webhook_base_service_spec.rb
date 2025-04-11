# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookBaseService do
  describe "#run" do
    let(:service) { described_class.new }
    let(:webhook_body) { {} }

    it "raises NotImplementedError for payment_or_refund_str" do
      expect { service.run(webhook_body) }.to raise_error(NotImplementedError)
    end

    context "when subclassed" do
      let(:service_class) do
        Class.new(described_class) do
          private

          def payment_or_refund_str
            "test"
          end

          def validate_webhook_body
            # No validation for test
          end

          def webhook_payment_or_refund_id
            "test_id"
          end

          def webhook_payment_or_refund_status
            "test_status"
          end
        end
      end

      let(:service) { service_class.new }

      it "returns extracted data" do
        result = service.run(webhook_body)
        
        expect(result).to include(
          payment_id: "test_id",
          status: "test_status",
          service_type: "front_office"
        )
      end

      context "with previous status" do
        before do
          service.previous_status = "test_status"
        end

        it "does not validate status transition when status is unchanged" do
          expect(service).not_to receive(:validate_status_transition)
          service.run(webhook_body)
        end

        context "with different status" do
          let(:service_class) do
            Class.new(described_class) do
              VALID_STATUS_TRANSITIONS = {
                "test_status" => %w[new_status]
              }.freeze

              private

              def payment_or_refund_str
                "test"
              end

              def validate_webhook_body
                # No validation for test
              end

              def webhook_payment_or_refund_id
                "test_id"
              end

              def webhook_payment_or_refund_status
                "new_status"
              end
            end
          end

          it "validates status transition" do
            expect(service).to receive(:validate_status_transition)
            service.run(webhook_body)
          end

          context "with invalid transition" do
            let(:service_class) do
              Class.new(described_class) do
                VALID_STATUS_TRANSITIONS = {
                  "test_status" => %w[other_status]
                }.freeze

                private

                def payment_or_refund_str
                  "test"
                end

                def validate_webhook_body
                  # No validation for test
                end

                def webhook_payment_or_refund_id
                  "test_id"
                end

                def webhook_payment_or_refund_status
                  "new_status"
                end
              end
            end

            it "raises InvalidGovpayStatusTransition" do
              expect { service.run(webhook_body) }.to raise_error(
                DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
                "Invalid test status transition from test_status to new_status"
              )
            end
          end
        end
      end
    end
  end

  describe "#sanitize_webhook_body" do
    let(:service) { described_class.new }
    let(:webhook_body) do
      {
        "resource" => {
          "email" => "test@example.com",
          "card_details" => { "number" => "1234" },
          "other_field" => "value"
        }
      }
    end

    it "removes sensitive information" do
      result = service.send(:sanitize_webhook_body, webhook_body)
      
      expect(result["resource"]).not_to include("email")
      expect(result["resource"]).not_to include("card_details")
      expect(result["resource"]).to include("other_field")
    end
  end
end
