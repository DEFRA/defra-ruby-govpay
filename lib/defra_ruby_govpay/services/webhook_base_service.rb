# frozen_string_literal: true

require "active_support/core_ext/object/blank"
require "active_support/core_ext/hash/keys"

module DefraRubyGovpay
  class WebhookBaseService
    class InvalidStatusTransition < StandardError; end

    attr_accessor :webhook_body, :previous_status

    # override this in subclasses
    VALID_STATUS_TRANSITIONS = {}.freeze

    def self.run(webhook_body, previous_status: nil)
      new.run(webhook_body, previous_status: previous_status)
    end

    def run(webhook_body, previous_status: nil)
      @webhook_body = webhook_body.deep_symbolize_keys
      @previous_status = previous_status

      validate_webhook_body

      # If we have a previous status and it's different from the current one, validate the transition
      if previous_status && previous_status != webhook_payment_or_refund_status
        validate_status_transition
      else
        DefraRubyGovpay.logger.warn(
          "Status \"#{@previous_status}\" unchanged in #{payment_or_refund_str} webhook update " \
          "#{log_webhook_context} "
        )
      end

      extract_data_from_webhook
    end

    private

    def validate_status_transition
      return if self.class::VALID_STATUS_TRANSITIONS[previous_status]&.include?(webhook_payment_or_refund_status)

      raise InvalidStatusTransition, "Invalid #{payment_or_refund_str} status transition " \
                                     "from #{previous_status} to #{webhook_payment_or_refund_status}" \
                                     "#{log_webhook_context}"
    end

    def extract_data_from_webhook
      {
        id: webhook_payment_id,
        status: webhook_payment_or_refund_status,
        webhook_body: webhook_body
      }
    end

    def webhook_payment_id
      @webhook_payment_id ||= webhook_body[:resource_id]
    end

    def log_webhook_context
      " for payment #{webhook_payment_id}"
    end

    def webhook_payment_or_refund_status
      @webhook_payment_or_refund_status ||= webhook_body.dig(:resource, :state, :status)
    end

    def webhook_resource_type
      @webhook_resource_type ||= webhook_body[:resource_type]&.downcase
    end

    # The following methods must be implemented in subclasses
    def payment_or_refund_str
      raise NotImplementedError
    end

    def validate_webhook_body
      raise NotImplementedError
    end
  end
end
