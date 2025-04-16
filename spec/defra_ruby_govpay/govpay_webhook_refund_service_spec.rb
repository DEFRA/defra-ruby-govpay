# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookRefundService do
  it_behaves_like "govpay webhook block yielding", :refund
  describe "#run" do
    let(:service) { described_class.new }
    let(:fixture_file) { File.read("spec/fixtures/files/webhook_refund_update_body.json") }
    let(:webhook_body) { JSON.parse(fixture_file) }

    describe "extracting refund data" do
      let(:result) { service.run(webhook_body) }

      it "extracts basic refund information" do
        expect(result).to include(
          payment_id: "789",
          status: "success"
        )
      end

      it "extracts refund details" do
        expect(result).to include(
          service_type: "front_office",
          amount: 2000,
          created_date: "2022-01-26T16:52:41.178Z"
        )
      end
    end

    context "with invalid webhook" do
      before do
        webhook_body.delete("refund_id")
      end

      it "raises an ArgumentError" do
        expect { service.run(webhook_body) }.to raise_error(
          ArgumentError,
          /Invalid refund webhook/
        )
      end
    end

    # Split the nested contexts to reduce nesting depth
    describe "status transition validation" do
      let(:service_with_valid_transition) { described_class.new }

      before do
        service_with_valid_transition.previous_status = "submitted"
      end

      it "allows valid transitions" do
        expect { service_with_valid_transition.run(webhook_body) }.not_to raise_error
      end
    end

    # Separate describe block for invalid transition tests to reduce nesting
    describe "invalid status transition" do
      let(:service_with_invalid_transition) { described_class.new }

      before do
        service_with_invalid_transition.previous_status = "error"
      end

      it "raises InvalidGovpayStatusTransition" do
        expect { service_with_invalid_transition.run(webhook_body) }.to raise_error(
          DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
          "Invalid refund status transition from error to success"
        )
      end
    end
  end
end
