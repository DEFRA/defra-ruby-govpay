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

      return unless webhook_payment_or_refund_status.blank?

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

    def extract_data_from_webhook
      data = super
      
      # Add payment-specific data
      data.merge!(
        amount: webhook_body.dig("resource", "amount"),
        description: webhook_body.dig("resource", "description"),
        reference: webhook_body.dig("resource", "reference"),
        created_date: webhook_body.dig("resource", "created_date"),
        moto: webhook_body.dig("resource", "moto") || false
      )

      # Add refund summary if present
      if webhook_body.dig("resource", "refund_summary").present?
        data[:refund_summary] = {
          status: webhook_body.dig("resource", "refund_summary", "status"),
          amount_available: webhook_body.dig("resource", "refund_summary", "amount_available"),
          amount_submitted: webhook_body.dig("resource", "refund_summary", "amount_submitted")
        }
      end

      data
    end
  end
end
