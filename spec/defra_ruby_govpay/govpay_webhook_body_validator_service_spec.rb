# frozen_string_literal: true

require "spec_helper"

RSpec.describe DefraRubyGovpay::GovpayWebhookBodyValidatorService do
  describe ".run" do

    subject(:run_service) { described_class.run(body: webhook_body, signature:) }

    let(:webhook_body) { file_fixture("files/webhook_payment_update_body.json") }
    let(:valid_front_office_signature) { SecureRandom.hex(10) }
    let(:valid_back_office_signature) { SecureRandom.hex(10) }
    let(:signature_service) { instance_double(DefraRubyGovpay::GovpayWebhookSignatureService) }

    before do
      allow(DefraRubyGovpay::GovpayWebhookSignatureService).to receive(:new).and_return(signature_service)
      allow(signature_service).to receive(:run).and_return(
        front_office: valid_front_office_signature,
        back_office: valid_back_office_signature
      )
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

    context "with a valid front office signature" do
      let(:signature) { valid_front_office_signature }

      it { expect(run_service).to be true }

      it "does not error" do
        expect { run_service }.not_to raise_error
      end
    end

    context "with a valid back office signature" do
      let(:signature) { valid_back_office_signature }

      it { expect(run_service).to be true }

      it "does not error" do
        expect { run_service }.not_to raise_error
      end
    end
  end
end
