# frozen_string_literal: true

module DefraRubyGovpay
  class WebhookBodyValidatorService
    class ValidationFailure < StandardError; end

    def self.run(body:, signature:)
      raise ValidationFailure, "Missing expected signature" if signature.blank?

      body_signatures = WebhookSignatureService.run(body:)
      return true if body_signatures[:front_office] == signature || body_signatures[:back_office] == signature

      raise ValidationFailure, "digest/signature header mismatch"
    end
  end
end
