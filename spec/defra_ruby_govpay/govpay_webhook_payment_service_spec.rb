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
          id: "hu20sqlact5260q2nanm0q8u93",
          status: "submitted"
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

      let(:result) { service.run(webhook_body) }

      it "extracts the correct payment ID" do
        expect(result[:id]).to eq("hu20sqlact5260q2nanm0q8u93")
      end

      it "extracts the correct payment status" do
        expect(result[:status]).to eq("submitted")
      end
    end

    # Split the nested contexts to reduce nesting depth
    describe "status transition validation" do
      it "allows valid transitions" do
        expect { described_class.run(webhook_body, previous_status: "created") }.not_to raise_error
      end
    end

    # Separate describe block for invalid transition tests to reduce nesting
    describe "invalid status transition" do
      it "raises InvalidGovpayStatusTransition" do
        expect { described_class.run(webhook_body, previous_status: "success") }.to raise_error(
          DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
          "Invalid payment status transition from success to submitted"
        )
      end
    end
  end
end
