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

      before do
        stub_const("TestWebhookService", service_class)
        stub_const("TestWebhookService::VALID_STATUS_TRANSITIONS", { "test_status" => %w[new_status] }.freeze)
      end

      describe "extracted data" do
        let(:result) { service.run(webhook_body) }

        it "includes payment ID and status" do
          expect(result).to include(
            payment_id: "test_id",
            status: "test_status"
          )
        end

        it "includes service type" do
          expect(result).to include(service_type: "front_office")
        end
      end

      context "with status updater block" do
        # Use fewer memoized helpers
        let(:captured_args) { {} }
        let(:block) { ->(args) { captured_args.merge!(args) } }
        let(:service) { service_class.new(block) }

        before { captured_args.clear }

        it "passes the correct id to the block" do
          allow(block).to receive(:call) { |args| captured_args.merge!(args) }
          service.run(webhook_body)
          expect(captured_args[:id]).to eq("test_id")
        end

        it "passes the correct status to the block" do
          allow(block).to receive(:call) { |args| captured_args.merge!(args) }
          service.run(webhook_body)
          expect(captured_args[:status]).to eq("test_status")
        end
      end

      # Split the nested contexts to reduce nesting depth
      describe "status transition validation" do
        let(:service_with_previous_status) { service_class.new }

        before do
          service_with_previous_status.previous_status = "test_status"
        end

        it "does not validate when status is unchanged" do
          allow(service_with_previous_status).to receive(:validate_status_transition)
          service_with_previous_status.run(webhook_body)
          expect(service_with_previous_status).not_to have_received(:validate_status_transition)
        end
      end

      # Separate describe block for different status tests to reduce nesting
      describe "with different status" do
        let(:different_status_class) do
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
              "new_status"
            end
          end
        end
        let(:service_with_different_status) { different_status_class.new }

        before do
          stub_const("TestDifferentStatusService", different_status_class)
          stub_const("TestDifferentStatusService::VALID_STATUS_TRANSITIONS", { "test_status" => %w[new_status] }.freeze)
          service_with_different_status.previous_status = "test_status"
        end

        it "validates status transition" do
          allow(service_with_different_status).to receive(:validate_status_transition)
          service_with_different_status.run(webhook_body)
          expect(service_with_different_status).to have_received(:validate_status_transition)
        end
      end

      # Separate describe block for invalid transition tests to reduce nesting
      describe "with invalid transition" do
        let(:invalid_transition_class) do
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
              "new_status"
            end
          end
        end
        let(:service_with_invalid_transition) { invalid_transition_class.new }

        before do
          stub_const("TestInvalidTransitionService", invalid_transition_class)
          stub_const("TestInvalidTransitionService::VALID_STATUS_TRANSITIONS", { "test_status" => %w[other_status] }.freeze)
          service_with_invalid_transition.previous_status = "test_status"
        end

        it "raises InvalidGovpayStatusTransition" do
          expect { service_with_invalid_transition.run(webhook_body) }.to raise_error(
            DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
            "Invalid test status transition from test_status to new_status"
          )
        end
      end
    end
  end
end
