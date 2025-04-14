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

      context "with status updater block" do
        let(:status_updater_called) { false }
        let(:status_updater) do
          lambda { |args|
            @status_updater_called = true
            @status_updater_args = args
          }
        end
        let(:service) { service_class.new(status_updater) }

        before do
          @status_updater_called = false
          @status_updater_args = nil
        end

        it "calls the status updater block with correct arguments" do
          service.run(webhook_body)

          expect(@status_updater_called).to be true
          expect(@status_updater_args).to include(
            id: "test_id",
            status: "test_status",
            type: "test"
          )
        end
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

end
