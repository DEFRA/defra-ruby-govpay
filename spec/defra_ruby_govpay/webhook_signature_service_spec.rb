# frozen_string_literal: true

require "spec_helper"

# rubocop:disable RSpec/MultipleMemoizedHelpers
module DefraRubyGovpay
  RSpec.describe WebhookSignatureService do
    describe ".run" do
      let(:front_office_secret) { SecureRandom.uuid }
      let(:back_office_secret) { SecureRandom.uuid }
      let(:digest) { OpenSSL::Digest.new("sha256") }

      before do
        DefraRubyGovpay.configure do |config|
          config.front_office_webhook_signing_secret = front_office_secret
          config.back_office_webhook_signing_secret = back_office_secret
        end
      end

      subject(:run_service) { described_class.run(body: webhook_body) }

      context "with a nil webhook body" do
        let(:webhook_body) { nil }

        it { expect { run_service }.not_to raise_error }
      end

      context "with a string webhook body" do
        let(:webhook_body) { "foo" }

        it { expect { run_service }.not_to raise_error }
      end

      context "with a complete webhook body" do
        let(:webhook_body) { file_fixture("files/webhook_payment_update_body.json") }
        let(:valid_front_office_signature) { OpenSSL::HMAC.hexdigest(digest, front_office_secret, webhook_body) }
        let(:valid_back_office_signature) { OpenSSL::HMAC.hexdigest(digest, back_office_secret, webhook_body) }

        it "returns correct signature for front office" do
          expect(run_service[:front_office]).to eq valid_front_office_signature
        end

        it "returns correct signature for back office" do
          expect(run_service[:back_office]).to eq valid_back_office_signature
        end

        it "does not raise an error" do
          expect { run_service }.not_to raise_error
        end
      end
    end
  end
end
# rubocop:enable RSpec/MultipleMemoizedHelpers
