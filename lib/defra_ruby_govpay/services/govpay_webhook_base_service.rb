# frozen_string_literal: true

require "active_support/core_ext/object/blank"

module DefraRubyGovpay
  class GovpayWebhookBaseService
    class InvalidGovpayStatusTransition < StandardError; end

    attr_accessor :webhook_body, :previous_status

    # override this in subclasses
    VALID_STATUS_TRANSITIONS = {}.freeze

    def self.run(webhook_body, previous_status: nil)
      new.run(webhook_body, previous_status: previous_status)
    end

    def initialize
      # No initialization needed
    end

    def run(webhook_body, previous_status: nil)
      @webhook_body = webhook_body
      @previous_status = previous_status

      validate_webhook_body

      # If we have a previous status and it's different from the current one, validate the transition
      if previous_status && previous_status != webhook_payment_or_refund_status
        validate_status_transition
      else
        DefraRubyGovpay.logger.warn(
          "Status \"#{@previous_status}\" unchanged in #{payment_or_refund_str} webhook update " \
          "#{log_webhook_context}"
        )
      end

      # Extract and return data from webhook
      extract_data_from_webhook
    end

    private

    def validate_status_transition
      return if self.class::VALID_STATUS_TRANSITIONS[previous_status]&.include?(webhook_payment_or_refund_status)

      raise InvalidGovpayStatusTransition, "Invalid #{payment_or_refund_str} status transition " \
                                           "from #{previous_status} to #{webhook_payment_or_refund_status}" \
                                           "#{log_webhook_context}"
    end

    def extract_data_from_webhook
      {
        id: webhook_payment_or_refund_id,
        status: webhook_payment_or_refund_status,
        webhook_body: webhook_body
      }
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

    def log_webhook_context
      raise NotImplementedError
    end
  end
end
