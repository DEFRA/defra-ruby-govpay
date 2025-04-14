# frozen_string_literal: true

module DefraRubyGovpay
  class GovpayWebhookJob
    def self.process(webhook_body)
      new.process(webhook_body)
    end

    def process(webhook_body)
      if webhook_body["resource_type"]&.downcase == "payment"
        DefraRubyGovpay::GovpayWebhookPaymentService.run(webhook_body)
      elsif webhook_body["refund_id"].present?
        DefraRubyGovpay::GovpayWebhookRefundService.run(webhook_body)
      else
        raise ArgumentError, "Unrecognised Govpay webhook type"
      end
    rescue StandardError => e
      handle_error(e, webhook_body)
    end

    private

    def sanitize_webhook_body(body)
      return body unless body.is_a?(Hash)

      sanitized = body.deep_dup

      if sanitized["resource"].is_a?(Hash)
        sanitized["resource"].delete("email")
        sanitized["resource"].delete("card_details")
      end

      sanitized
    end

    def handle_error(error, webhook_body)
      service_type = webhook_body.dig("resource", "moto") ? "back_office" : "front_office"

      error_data = {
        error: error,
        refund_id: webhook_body&.dig("resource", "refund_id") || webhook_body&.dig("refund_id"),
        payment_id: webhook_body&.dig("resource", "payment_id") || webhook_body&.dig("payment_id"),
        service_type: service_type,
        webhook_body: sanitize_webhook_body(webhook_body)
      }

      # Log the error if a logger is available
      DefraRubyGovpay.logger.error("Error processing Govpay webhook: #{error.message}") if defined?(DefraRubyGovpay.logger)

      error_data
    end
  end
end
