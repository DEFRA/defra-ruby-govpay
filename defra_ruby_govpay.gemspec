# frozen_string_literal: true

require_relative "lib/defra_ruby_govpay/version"

Gem::Specification.new do |spec|
  spec.name = "defra_ruby_govpay"
  spec.version = DefraRubyGovpay::VERSION
  spec.authors = ["Jerome Pratt"]
  spec.email = ["jerome.pratt@defra.gov.uk"]

  spec.summary = "A Ruby gem facilitating integration with Govpay services in ruby applications."
  spec.description = "This gem abstracts the Govpay integration code, facilitating " \
                     "integration within defra ruby applications."
  spec.homepage = "https://github.com/DEFRA/defra-ruby-govpay"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["source_code_uri"] = "https://github.com/DEFRA/defra-ruby-govpay"

  spec.add_dependency "rest-client", "~> 2.1"
  spec.require_paths = ["lib"]

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.metadata["rubygems_mfa_required"] = "true"
end
