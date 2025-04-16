# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookPaymentService do
  it_behaves_like "govpay webhook data extraction", :payment
  describe "#run" do
    let(:service) { described_class.new }
    let(:fixture_file) { File.read("spec/fixtures/files/webhook_payment_update_body.json") }
    let(:webhook_body) { JSON.parse(fixture_file) }

    describe "extracting payment data" do
      let(:result) { service.run(webhook_body) }

      it "extracts basic payment information" do
        expect(result).to include(
          payment_id: "hu20sqlact5260q2nanm0q8u93",
          status: "submitted"
        )
      end

      it "extracts service type and amount" do
        expect(result).to include(
          service_type: "front_office",
          amount: 5000
        )
      end

      it "extracts payment description and reference" do
        expect(result).to include(
          description: "Pay your council tax",
          reference: "12345"
        )
      end

      it "extracts payment date and moto flag" do
        expect(result).to include(
          created_date: "2021-10-19T10:05:45.454Z",
          moto: false
        )
      end

      it "extracts refund summary information" do
        expect(result[:refund_summary]).to include(
          status: "pending",
          amount_available: 5000,
          amount_submitted: 0
        )
      end
    end

    context "with invalid webhook type" do
      before do
        webhook_body["resource_type"] = "invalid_type"
      end

      it "raises an ArgumentError" do
        expect { service.run(webhook_body) }.to raise_error(
          ArgumentError,
          "Invalid webhook type invalid_type"
        )
      end
    end

    context "with missing payment status" do
      before do
        webhook_body["resource"]["state"].delete("status")
      end

      it "raises an ArgumentError" do
        expect { service.run(webhook_body) }.to raise_error(
          ArgumentError,
          /Webhook body missing payment status/
        )
      end
    end

    context "with back office payment" do
      before do
        webhook_body["resource"]["moto"] = true
      end

      it "identifies the service type as back_office" do
        result = service.run(webhook_body)
        expect(result[:service_type]).to eq("back_office")
      end
    end

    # Split the nested contexts to reduce nesting depth
    describe "status transition validation" do
      let(:service_with_valid_transition) { described_class.new }

      before do
        service_with_valid_transition.previous_status = "created"
      end

      it "allows valid transitions" do
        expect { service_with_valid_transition.run(webhook_body) }.not_to raise_error
      end
    end

    # Separate describe block for invalid transition tests to reduce nesting
    describe "invalid status transition" do
      let(:service_with_invalid_transition) { described_class.new }

      before do
        service_with_invalid_transition.previous_status = "success"
      end

      it "raises InvalidGovpayStatusTransition" do
        expect { service_with_invalid_transition.run(webhook_body) }.to raise_error(
          DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
          "Invalid payment status transition from success to submitted"
        )
      end
    end
  end
end
