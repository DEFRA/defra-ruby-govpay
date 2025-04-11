# frozen_string_literal: true

module DefraRubyGovpay
  class GovpayWebhookRefundService < GovpayWebhookBaseService

    VALID_STATUS_TRANSITIONS = {
      "submitted" => %w[success],
      "success" => %w[],
      "error" => %w[]
    }.freeze

    private

    def payment_or_refund_str
      "refund"
    end

    def validate_webhook_body
      return if webhook_payment_or_refund_id.present? && webhook_payment_or_refund_status.present?

      raise ArgumentError, "Invalid refund webhook: #{webhook_body}"
    end

    def webhook_payment_id
      @webhook_payment_id ||= webhook_body["payment_id"]
    end

    def webhook_payment_or_refund_id
      @webhook_payment_or_refund_id ||= webhook_body["refund_id"]
    end

    def webhook_payment_or_refund_status
      @webhook_payment_or_refund_status ||= webhook_body["status"]
    end

    def extract_data_from_webhook
      data = super
      
      # Add refund-specific data
      data.merge!(
        payment_id: webhook_payment_id,
        amount: webhook_body["amount"],
        created_date: webhook_body["created_date"]
      )

      data
    end
  end
end
