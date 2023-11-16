# frozen_string_literal: true

require "rest-client"

module DefraRubyGovpay

  # Custom error class to handle Govpay API errors
  class GovpayApiError < StandardError
    def initialize(msg = "Govpay API error")
      super
    end
  end

  # The API class is responsible for making requests to the Govpay API.
  # It handles the construction of request URLs, headers, and payload,
  # and also deals with any errors that occur during the API request.

  class API

    def initialize(host_is_back_office:)
      @host_is_back_office = host_is_back_office
    end

    def send_request(method:, path:, params: nil, is_moto: false)
      @is_moto = is_moto
      DefraRubyGovpay.logger.debug build_log_message(method, path, params)

      begin
        response = execute_request(method, path, params)
        DefraRubyGovpay.logger.debug "Received response from Govpay: #{response}"
        response
      rescue StandardError => e
        handle_error(e, method, path, params)
      end
    end

    private

    def build_log_message(method, path, params)
      "#{self.class} sending #{method} request to govpay (#{path}), params: #{params}, moto: #{@is_moto}, " \
        "govpay API token ending \"#{bearer_token[-5..]}\""
    end

    def execute_request(method, path, params)
      RestClient::Request.execute(
        method: method,
        url: url(path),
        payload: payload(params),
        headers: {
          "Authorization" => "Bearer #{bearer_token}",
          "Content-Type" => "application/json"
        }
      )
    end

    def handle_error(error, method, path, params)
      error_message = "Error sending request to govpay (#{method} #{path}, params: #{params}), " \
                      "response body: #{error.response&.body}: #{error}"
      DefraRubyGovpay.logger.error error_message
      raise GovpayApiError, error_message
    end

    def govpay_url
      @govpay_url ||= DefraRubyGovpay.configuration.govpay_url
    end

    def url(path)
      "#{govpay_url}#{path}"
    end

    def front_office_token
      @front_office_token ||= DefraRubyGovpay.configuration.govpay_front_office_api_token
    end

    def back_office_token
      @back_office_token ||= DefraRubyGovpay.configuration.govpay_back_office_api_token
    end

    def bearer_token
      if @host_is_back_office
        @is_moto ? back_office_token : front_office_token
      else
        front_office_token
      end
    end

    def payload(params)
      return nil if params.nil? || params.empty?

      params.compact.to_json
    end
  end
end
