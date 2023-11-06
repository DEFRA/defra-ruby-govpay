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

  # The default logger for this gem writes to console. Redirect here to avoid cluttering rspec output.
  original_stderr = $stderr
  original_stdout = $stdout

  config.before(:all) do
    # Redirect stderr and stdout
    $stderr = File.open(File::NULL, "w")
    $stdout = File.open(File::NULL, "w")
  end

  config.after(:all) do
    $stderr = original_stderr
    $stdout = original_stdout
  end
end
