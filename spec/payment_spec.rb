# frozen_string_literal: true

require "spec_helper"

module DefraRubyGovpay
  RSpec.describe Payment do
    subject(:payment) { described_class.new(params) }

    let(:params) { JSON.parse(file_fixture("get_payment_response_success.json")) }

    describe "#refundable?" do
      context "when refundable" do
        it { expect(payment.refundable?).to be true }
      end
    end

    describe "parsing arrays" do
      let(:params) { super().merge(array: [1, 2, 3]) }

      it "creates an array openstruct" do
        expect(payment.array).to eq [1, 2, 3]
      end
    end
  end
end
