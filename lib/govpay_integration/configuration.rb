# frozen_string_literal: true

module GovpayIntegration
  # The Configuration class is responsible for storing configurable settings
  # for the GovpayIntegration module. You can set different options like
  # API tokens, host preferences, and other necessary configurations here.
  class Configuration
    attr_accessor :govpay_url, :govpay_front_office_api_token, :govpay_back_office_api_token, :host_is_back_office
  end
end
