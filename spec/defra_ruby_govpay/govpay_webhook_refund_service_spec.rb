# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookRefundService do
  it_behaves_like "govpay webhook data extraction", :refund
  it_behaves_like "govpay status transitions", :refund

  describe "#run" do
    let(:service) { described_class.new }
    let(:fixture_file) { File.read("spec/fixtures/files/webhook_refund_update_body.json") }
    let(:webhook_body) { JSON.parse(fixture_file) }

    describe "extracting refund data" do
      let(:result) { service.run(webhook_body) }

      it "extracts basic refund information" do
        expect(result).to include(
          id: "345",
          status: "success"
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

    describe "status transition validation" do
      it_behaves_like "valid and invalid transitions", "submitted",
                      %w[success],
                      %w[error]

      it_behaves_like "no valid transitions", "success"
      it_behaves_like "no valid transitions", "error"
    end
  end
end
