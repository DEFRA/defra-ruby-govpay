# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe DefraRubyGovpay::API do
  let(:govpay_host) { "https://publicapi.payments.service.gov.uk" }
  let(:config) do
    instance_double(DefraRubyGovpay::Configuration,
                    govpay_url: govpay_host,
                    host_is_back_office: false,
                    govpay_front_office_api_token: "front_office_token",
                    govpay_back_office_api_token: "back_office_token")
  end
  let(:govpay_service) { described_class.new(config) }

  before do
    stub_request(:any, /.*#{govpay_host}.*/).to_return(
      status: 200,
      body: file_fixture("create_payment_created_response.json")
    )
  end

  describe "#send_request" do
    context "when the request is valid" do
      it "returns a successful response" do
        response = govpay_service.send_request(method: :get, path: "/valid_path", params: { valid: "params" }, is_moto: false)

        # Here, you need to add assertions based on the expected successful response structure
        expect(response).to be_a(RestClient::Response)
        # Add more assertions here based on the response structure
      end
    end

    context "when the request is from the back-office" do
      before do
        allow(config).to receive(:host_is_back_office).and_return(true)
      end

      it "sends the moto flag to GovPay" do
        govpay_service.send_request(method: :get, path: "/valid_path", params: { valid: "params", moto: true }, is_moto: true)

        expect(WebMock).to have_requested(:get, /.*#{govpay_host}.*/).with(body: hash_including(moto: true))
      end
    end

    context "when the request is from the front-office" do
      before do
        allow(config).to receive(:host_is_back_office).and_return(false)
      end

      it "does not send the moto flag to GovPay" do
        govpay_service.send_request(method: :get, path: "/valid_path", params: { valid: "params", moto: false }, is_moto: false)

        expect(WebMock).to have_requested(:get, /.*#{govpay_host}.*/).with(body: hash_including(moto: false))
      end
    end

    context "when the request is invalid" do
      before do
        stub_request(:any, /.*#{govpay_host}.*/).to_return(
          status: 400,
          body: file_fixture("create_payment_error_response.json")
        )
      end

      it "raises a GovpayApiError" do
        expect do
          govpay_service.send_request(method: :get, path: "/invalid_path", params: { invalid: "params" }, is_moto: false)
        end.to raise_error(DefraRubyGovpay::GovpayApiError)
      end
    end
  end
end
