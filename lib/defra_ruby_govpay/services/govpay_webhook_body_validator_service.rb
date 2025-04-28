# frozen_string_literal: true

module DefraRubyGovpay
  class GovpayWebhookBodyValidatorService
    class ValidationFailure < StandardError; end

    def self.run(body:, signature:)
      raise ValidationFailure, "Missing expected signature" if signature.blank?

      body_signature = GovpayWebhookSignatureService.run(body:)
      return true if body_signature == signature

      raise ValidationFailure, "digest/signature header mismatch"
    end
  end
end
