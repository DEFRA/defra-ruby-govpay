# frozen_string_literal: true

module DefraRubyGovpay
  class GovpayWebhookBaseService
    class InvalidGovpayStatusTransition < StandardError; end

    attr_accessor :webhook_body, :previous_status

    # override this in subclasses
    VALID_STATUS_TRANSITIONS = {}.freeze

    def self.run(webhook_body)
      new.run(webhook_body)
    end

    def run(webhook_body)
      @webhook_body = webhook_body

      validate_webhook_body

      if previous_status && webhook_payment_or_refund_status == previous_status
        # Status unchanged
      else
        validate_status_transition if previous_status
      end

      extract_data_from_webhook
    end

    private

    def validate_status_transition
      return if self.class::VALID_STATUS_TRANSITIONS[previous_status]&.include?(webhook_payment_or_refund_status)

      raise InvalidGovpayStatusTransition, "Invalid #{payment_or_refund_str} status transition " \
                                          "from #{previous_status} to #{webhook_payment_or_refund_status}"
    end

    def extract_data_from_webhook
      {
        payment_id: webhook_payment_or_refund_id,
        status: webhook_payment_or_refund_status,
        service_type: service_type
      }
    end

    def service_type
      webhook_body.dig("resource", "moto") ? "back_office" : "front_office"
    end

    def sanitize_webhook_body
      return webhook_body unless webhook_body.is_a?(Hash)

      sanitized = webhook_body.deep_dup

      if sanitized["resource"].is_a?(Hash)
        sanitized["resource"].delete("email")
        sanitized["resource"].delete("card_details")
      end

      sanitized
    end

    # The following methods must be implemented in subclasses
    def payment_or_refund_str
      raise NotImplementedError
    end

    def validate_webhook_body
      raise NotImplementedError
    end

    def webhook_payment_or_refund_id
      raise NotImplementedError
    end

    def webhook_payment_or_refund_status
      raise NotImplementedError
    end
  end
end
