# frozen_string_literal: true

module DefraRubyGovpay
  class GovpayWebhookPaymentService < GovpayWebhookBaseService

    VALID_STATUS_TRANSITIONS = {
      "created" => %w[started submitted success failed cancelled error],
      "started" => %w[submitted success failed cancelled error],
      "submitted" => %w[success failed cancelled error],
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

      return if webhook_payment_or_refund_status && !webhook_payment_or_refund_status.to_s.strip.empty?

      raise ArgumentError, "Webhook body missing payment status: #{webhook_body}"
    end

    def webhook_resource_type
      @webhook_resource_type ||= webhook_body["resource_type"]&.downcase
    end

    def webhook_payment_or_refund_id
      @webhook_payment_or_refund_id ||= webhook_body.dig("resource", "payment_id")
    end

    def webhook_payment_or_refund_status
      @webhook_payment_or_refund_status ||= webhook_body.dig("resource", "state", "status")
    end
  end
end
