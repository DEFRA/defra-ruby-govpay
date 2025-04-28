# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookBodyValidatorService do
  describe ".run" do

    let(:headers) { "Pay-Signature" => signature }
    let(:webhook_body) { file_fixture("files/webhook_payment_update_body.json") }
    let(:webhook_signing_secret) { ENV.fetch("WCRS_GOVPAY_CALLBACK_WEBHOOK_SIGNING_SECRET") }
    let(:digest) { OpenSSL::Digest.new("sha256") }
    let(:valid_signature) { SecureRandom.hex(10) }
    let(:signature_service) { instance_double(DefraRubyGovpay::GovpayWebhookSignatureService) }
    let(:signature) { nil }

    subject(:run_service) { described_class.run(body: webhook_body, signature:) }

    before do
      allow(DefraRubyGovpay::GovpayWebhookSignatureService).to receive(:new).and_return(signature_service)
      allow(signature_service).to receive(:run).and_return(valid_signature)
    end

    shared_examples "fails validation" do
      it "raises an exception" do
        expect { run_service }.to raise_error(DefraRubyGovpay::GovpayWebhookBodyValidatorService::ValidationFailure)
      end
    end

    context "with a nil signature" do
      let(:signature) { nil }

      it_behaves_like "fails validation"
    end

    context "with an invalid signature" do
      let(:signature) { "foo" }

      it_behaves_like "fails validation"
    end

    context "with a valid signature" do
      let(:signature) { valid_signature }

      it { expect(run_service).to be true }

      it "does not report an error" do
        expect { run_service }.not_to raise_error
      end
    end
  end
end
