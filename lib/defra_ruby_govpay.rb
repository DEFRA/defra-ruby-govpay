# frozen_string_literal: true

require "json"
require_relative "defra_ruby_govpay/version"
require_relative "defra_ruby_govpay/configuration"
require_relative "defra_ruby_govpay/object"
require_relative "defra_ruby_govpay/payment"
require_relative "defra_ruby_govpay/refund"
require_relative "defra_ruby_govpay/error"
require_relative "defra_ruby_govpay/api"

# The DefraRubyGovpay module facilitates integration with Govpay services.
# It provides a convenient and configurable way to interact with Govpay APIs in Defra's ruby applications.
module DefraRubyGovpay
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end

  # Use DefraRubyGovpay.logger if it exists, else use a simple console logger
  def self.logger
    @logger ||= defined?(Rails) ? DefraRubyGovpay.logger : Logger.new($stdout)
  end

  def self.logger=(logger)
    @logger = logger
  end
end
