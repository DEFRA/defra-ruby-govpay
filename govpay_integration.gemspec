# frozen_string_literal: true

require_relative "lib/govpay_integration/version"

Gem::Specification.new do |spec|
  spec.name = "govpay_integration"
  spec.version = GovpayIntegration::VERSION
  spec.authors = ["Jerome Pratt"]
  spec.email = ["jerome.pratt@defra.gov.uk"]

  spec.summary = "A Ruby gem facilitating integration with Govpay services in WCR and WEX applications."
  spec.description = "This gem abstracts the Govpay integration code, enabling seamless and reusable integration within the WCR and WEX applications. It is designed to make few assumptions about the data models of the applications that utilize it, aiming to be as flexible and adaptable as possible."
  spec.homepage = "https://yourgemhomepage.com"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["allowed_push_host"] = "https://yourgemserver.com"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/yourorganization/govpay_integration"
  spec.metadata["changelog_uri"] = "https://github.com/yourorganization/govpay_integration/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) || f.start_with?(*%w[bin/ test/ spec/ features/ .git .circleci appveyor])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
