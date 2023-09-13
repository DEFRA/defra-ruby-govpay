# frozen_string_literal: true

require "rest-client"

module GovpayIntegration
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
    def initialize(config = GovpayIntegration.configuration)
      @config = config
      @is_back_office = config.host_is_back_office
      @front_office_token = config.govpay_front_office_api_token
      @back_office_token = config.govpay_back_office_api_token
    end

    def send_request(method:, path:, params: nil, is_moto: false)
      puts build_log_message(method, path, params, is_moto)

      begin
        response = execute_request(method, path, params, is_moto)
        puts "Received response from Govpay: #{response}"
        response
      rescue StandardError => error
        handle_error(error, method, path, params)
      end
    end

    private

    def build_log_message(method, path, params, is_moto)
      "#{self.class} sending #{method} request to govpay (#{path}), params: #{params}, moto: #{is_moto}"
    end

    def execute_request(method, path, params, is_moto)
      RestClient::Request.execute(
        method: method,
        url: url(path),
        payload: payload(params),
        headers: {
          "Authorization" => "Bearer #{bearer_token(is_moto)}",
          "Content-Type" => "application/json"
        }
      )
    end

    def handle_error(error, method, path, params)
      error_message = "Error sending request to govpay (#{method} #{path}, params: #{params}): #{error}"
      puts error_message
      raise GovpayApiError, error_message
    end

    def url(path)
      "#{@config.govpay_url}#{path}"
    end

    def bearer_token(is_moto)
      return @front_office_token unless @is_back_office

      is_moto ? @back_office_token : @front_office_token
    end

    def payload(params)
      return nil if params.nil? || params.empty?

      params.compact.to_json
    end
  end
end
