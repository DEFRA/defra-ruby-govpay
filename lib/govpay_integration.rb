# frozen_string_literal: true

require "json"
require_relative "govpay_integration/version"
require_relative "govpay_integration/configuration"
require_relative "govpay_integration/object"
require_relative "govpay_integration/payment"
require_relative "govpay_integration/refund"
require_relative "govpay_integration/error"
require_relative "govpay_integration/api"

# The GovpayIntegration module facilitates integration with Govpay services.
# It provides a convenient and configurable way to interact with Govpay APIs in Defra's ruby applications.
module GovpayIntegration
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end
end
