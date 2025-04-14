# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookRefundService do
  describe "#run" do
    let(:service) { described_class.new }
    let(:fixture_file) { File.read("spec/fixtures/files/webhook_refund_update_body.json") }
    let(:webhook_body) { JSON.parse(fixture_file) }

    it "extracts refund data from the webhook body" do
      result = service.run(webhook_body)

      expect(result).to include(
        payment_id: "789",
        status: "success",
        service_type: "front_office",
        amount: 2000,
        created_date: "2022-01-26T16:52:41.178Z"
      )
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

    context "with status transition validation" do
      before do
        service.previous_status = "submitted"
      end

      it "allows valid transitions" do
        expect { service.run(webhook_body) }.not_to raise_error
      end

      context "with invalid transition" do
        before do
          service.previous_status = "error"
        end

        it "raises InvalidGovpayStatusTransition" do
          expect { service.run(webhook_body) }.to raise_error(
            DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
            "Invalid refund status transition from error to success"
          )
        end
      end
    end
  end
end
