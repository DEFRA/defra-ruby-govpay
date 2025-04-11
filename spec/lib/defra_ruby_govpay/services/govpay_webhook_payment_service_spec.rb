# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookPaymentService do
  describe "#run" do
    let(:service) { described_class.new }
    let(:fixture_file) { File.read("spec/fixtures/files/webhook_payment_update_body.json") }
    let(:webhook_body) { JSON.parse(fixture_file) }

    it "extracts payment data from the webhook body" do
      result = service.run(webhook_body)
      
      expect(result).to include(
        payment_id: "hu20sqlact5260q2nanm0q8u93",
        status: "submitted",
        service_type: "front_office",
        amount: 5000,
        description: "Pay your council tax",
        reference: "12345",
        created_date: "2021-10-19T10:05:45.454Z",
        moto: false
      )

      expect(result[:refund_summary]).to include(
        status: "pending",
        amount_available: 5000,
        amount_submitted: 0
      )
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

    context "with status transition validation" do
      before do
        service.previous_status = "created"
      end

      it "allows valid transitions" do
        expect { service.run(webhook_body) }.not_to raise_error
      end

      context "with invalid transition" do
        before do
          service.previous_status = "success"
        end

        it "raises InvalidGovpayStatusTransition" do
          expect { service.run(webhook_body) }.to raise_error(
            DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
            "Invalid payment status transition from success to submitted"
          )
        end
      end
    end
  end
end
