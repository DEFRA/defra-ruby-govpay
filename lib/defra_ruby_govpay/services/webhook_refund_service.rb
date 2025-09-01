# frozen_string_literal: true

module DefraRubyGovpay
  class WebhookRefundService < WebhookBaseService

    VALID_STATUS_TRANSITIONS = {
      "submitted" => %w[success error],
      "success" => %w[],
      "error" => %w[]
    }.freeze

    private

    def payment_or_refund_str
      "refund"
    end

    def validate_webhook_body
      return if webhook_body[:event_type] == "card_payment_refunded" &&
                webhook_payment_id.present? &&
                webhook_refund_status.present?

      raise ArgumentError, "Invalid refund webhook: #{WebhookSanitizerService.call(webhook_body)}"
    end

    def webhook_refund_status
      @webhook_refund_status ||= webhook_body.dig(:resource, :state, :status)
    end

  end
end
