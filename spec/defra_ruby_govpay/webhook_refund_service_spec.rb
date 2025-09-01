# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::WebhookRefundService do
  it_behaves_like "webhook data extraction", :refund
  it_behaves_like "status transitions", :refund

  describe "#run" do
    let(:service) { described_class.new }
    let(:fixture_file) { File.read("spec/fixtures/files/webhook_refund_update_body.json") }
    let(:webhook_body) { JSON.parse(fixture_file) }

    describe "extracting refund data" do
      let(:result) { service.run(webhook_body) }

      it "extracts basic refund information" do
        expect(result).to include(
          id: webhook_body["resource_id"],
          status: "success"
        )
      end
    end

    context "with invalid webhook" do
      before { webhook_body.delete("resource_id") }

      it "raises an ArgumentError" do
        expect { service.run(webhook_body) }.to raise_error(ArgumentError, /Invalid refund webhook/)
      end
    end

    context "with a non-refund event_type" do
      before { webhook_body["event_type"] = "card_payment_succeeded" }

      it "raises an ArgumentError" do
        expect { service.run(webhook_body) }.to raise_error(ArgumentError, /Invalid refund webhook/)
      end
    end

    describe "status transition validation" do
      it_behaves_like "a valid transition", "submitted", "success"
      it_behaves_like "a valid transition", "submitted", "error"
      it_behaves_like "no valid transitions", "success"
      it_behaves_like "no valid transitions", "error"
    end
  end
end
