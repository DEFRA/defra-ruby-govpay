# frozen_string_literal: true

require "spec_helper"

module DefraRubyGovpay
  RSpec.describe WebhookSanitizerService do
    describe ".call" do
      subject(:sanitize) { described_class.call(webhook_body) }

      context "when webhook_body is not a hash" do
        let(:webhook_body) { "not a hash" }

        it "returns the webhook_body unchanged" do
          expect(sanitize).to eq(webhook_body)
        end
      end

      context "when webhook_body is a hash" do
        context "with no resource key" do
          let(:webhook_body) { { "key" => "value" } }

          it "returns the webhook_body unchanged" do
            expect(sanitize).to eq(webhook_body)
          end
        end

        context "with resource key that is not a hash" do
          let(:webhook_body) { { "resource" => "not a hash" } }

          it "returns the webhook_body unchanged" do
            expect(sanitize).to eq(webhook_body)
          end
        end

        context "with resource key containing sensitive information" do
          let(:webhook_body) do
            {
              "resource" => {
                "email" => "user@example.com",
                "card_details" => { "card_number" => "1234 5678 9012 3456" },
                "amount" => 5000,
                "description" => "Pay your council tax"
              }
            }
          end

          it "removes sensitive information" do
            expect(sanitize["resource"]).not_to include("email", "card_details")
          end

          it "preserves non-sensitive information" do
            expect(sanitize["resource"]).to include(
              "amount" => 5000,
              "description" => "Pay your council tax"
            )
          end
        end
      end
    end
  end
end
