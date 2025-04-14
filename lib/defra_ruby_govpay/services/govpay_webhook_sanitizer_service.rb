# frozen_string_literal: true

module DefraRubyGovpay
  class GovpayWebhookSanitizerService
    def self.call(webhook_body)
      new.call(webhook_body)
    end

    def call(webhook_body)
      return webhook_body unless webhook_body.is_a?(Hash)

      # Create a deep copy to avoid modifying the original hash
      sanitized = Marshal.load(Marshal.dump(webhook_body))

      if sanitized["resource"].is_a?(Hash)
        sanitized["resource"].delete("email")
        sanitized["resource"].delete("card_details")
      end

      sanitized
    end
  end
end
