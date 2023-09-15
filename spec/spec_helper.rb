# frozen_string_literal: true

require "defra_ruby_govpay"
require "defra_ruby_govpay/api"
require "defra_ruby_govpay/version"
require "defra_ruby_govpay/configuration"
require "support/fixture_helper"

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.include FixtureHelper

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
