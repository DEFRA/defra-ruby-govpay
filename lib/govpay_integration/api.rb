require "rest-client"

module GovpayIntegration
  class GovpayApiError < StandardError
    def initialize(msg = "Govpay API error")
      super
    end
  end

  class API
    def initialize(config = GovpayIntegration.configuration)
      @config = config
      @is_back_office = config.host_is_back_office
      @front_office_token = config.govpay_front_office_api_token
      @back_office_token = config.govpay_back_office_api_token
    end

    def send_request(method:, path:, params: nil, is_moto: false)
      puts "#{self.class} sending #{method} request to govpay (#{path}), " \
                    "params: #{params}, moto: #{is_moto}"
      begin
        response = RestClient::Request.execute(
          method: method,
          url: url(path),
          payload: payload(params),
          headers: {
            "Authorization" => "Bearer #{bearer_token(is_moto)}",
            "Content-Type" => "application/json"
          }
        )

        puts "Received response from Govpay: #{response}"
        response
      rescue StandardError => e
        error_message = "Error sending request to govpay (#{method} #{path}, params: #{params}): #{e}"
        puts error_message
        # notify_error(e, method: method, path: path, params: params)
        raise GovpayApiError.new(error_message)
      end
    end

    private

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
