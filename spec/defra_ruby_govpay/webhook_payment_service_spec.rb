# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::WebhookPaymentService do
  it_behaves_like "webhook data extraction", :payment
  it_behaves_like "status transitions", :payment

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

    context "when the resource_type has different casings" do
      shared_examples "handles case-insensitive resource_type as payment" do |resource_type_value|
        before do
          webhook_body["resource_type"] = resource_type_value
        end

        it { expect { service.run(webhook_body) }.not_to raise_error }
      end

      %w[payment PAYMENT].each do |case_variant|
        it_behaves_like "handles case-insensitive resource_type as payment", case_variant
      end
    end

    describe "status transition validation" do
      # created
      %w[started submitted success failed cancelled expired error].each do |new_status|
        it_behaves_like "a valid transition", "created", new_status
      end

      # started
      %w[submitted success failed cancelled expired error].each do |new_status|
        it_behaves_like "a valid transition", "started", new_status
      end
      it_behaves_like "an invalid transition", "started", "created"

      # submitted
      %w[success failed cancelled expired error].each do |new_status|
        it_behaves_like "a valid transition", "submitted", new_status
      end
      %w[created started].each do |new_status|
        it_behaves_like "an invalid transition", "submitted", new_status
      end

      # end states
      it_behaves_like "no valid transitions", "success"
      it_behaves_like "no valid transitions", "failed"
      it_behaves_like "no valid transitions", "cancelled"
      it_behaves_like "no valid transitions", "expired"
      it_behaves_like "no valid transitions", "error"
    end
  end
end
