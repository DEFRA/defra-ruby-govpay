# frozen_string_literal: true

require_relative "lib/govpay_integration/version"

Gem::Specification.new do |spec|
  spec.name = "govpay_integration"
  spec.version = GovpayIntegration::VERSION
  spec.authors = ["Jerome Pratt"]
  spec.email = ["jerome.pratt@defra.gov.uk"]

  spec.summary = "A Ruby gem facilitating integration with Govpay services in ruby applications."
  spec.description = "This gem abstracts the Govpay integration code, facilitating " \
                     "integration within defra ruby applications."
  spec.homepage = "https://github.com/DEFRA/defra-ruby-govpay"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["source_code_uri"] = "https://github.com/yourorganization/govpay_integration"

  spec.add_dependency "rest-client", "~> 2.1"
  spec.require_paths = ["lib"]
end
