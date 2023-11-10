# frozen_string_literal: true

require "webmock/rspec"

RSpec.describe DefraRubyGovpay::API do
  let(:govpay_host) { "https://publicapi.payments.service.gov.uk" }
  let(:govpay_service) { described_class.new }
  let(:config) { DefraRubyGovpay.configuration }

  before do

    DefraRubyGovpay.configure do |config|
      config.govpay_url = govpay_host
      config.host_is_back_office = false
      config.govpay_front_office_api_token = "front_office_token"
      config.govpay_back_office_api_token = "back_office_token"
    end

    stub_request(:any, /.*#{govpay_host}.*/).to_return(
      status: 200,
      body: file_fixture("create_payment_created_response.json")
    )
  end

  describe "#send_request" do

    context "when the request is valid" do
      it "returns a successful response" do
        response = govpay_service.send_request(method: :get, path: "/valid_path", params: { valid: "params" }, is_moto: false)

        aggregate_failures do
          expect(response).to be_a(RestClient::Response)
          expect(JSON.parse(response.body)).to include("state", "amount", "payment_id")
        end
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

    context "when the govpay API retuns a 422 response" do

      let(:logger) { DefraRubyGovpay.logger }

      before do
        stub_request(:any, /.*#{govpay_host}.*/).to_return(
          status: 422,
          body: {
            field: "description",
            code: "P0102",
            description: "Invalid attribute"
          }.to_json
        )

        # Avoid cluttering unit test output
        DefraRubyGovpay.logger = Logger.new("/dev/null")
        allow(logger).to receive(:error).with(any_args).and_call_original
      end

      # rubocop:disable RSpec/ExampleLength:
      it "logs the error response details" do
        govpay_service.send_request(method: :get, path: "/valid_path", params: { valid: "params", moto: false })
      rescue DefraRubyGovpay::GovpayApiError
        aggregate_failures do
          expect(logger).to have_received(:error).with(/field.*description/)
          expect(logger).to have_received(:error).with(/code.*P0102/)
          expect(logger).to have_received(:error).with(/description.*Invalid attribute/)
        end
      end
      # rubocop:enable RSpec/ExampleLength:
    end
  end
end
