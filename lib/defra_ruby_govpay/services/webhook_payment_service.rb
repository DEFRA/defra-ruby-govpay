# frozen_string_literal: true

module DefraRubyGovpay
  class WebhookPaymentService < WebhookBaseService

    VALID_STATUS_TRANSITIONS = {
      "created" => %w[started submitted success failed cancelled expired error],
      "started" => %w[submitted success failed cancelled expired error],
      "submitted" => %w[success failed cancelled expired error],
      "success" => %w[],
      "failed" => %w[],
      "cancelled" => %w[],
      "error" => %w[]
    }.freeze

    private

    def payment_or_refund_str
      "payment"
    end

    def validate_webhook_body
      raise ArgumentError, "Invalid webhook type #{webhook_resource_type}" unless webhook_resource_type == "payment"

      return unless webhook_payment_or_refund_status.blank?

      raise ArgumentError, "Webhook body missing payment status: #{WebhookSanitizerService.call(webhook_body)}"
    end
  end
end
