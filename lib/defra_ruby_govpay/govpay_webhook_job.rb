# frozen_string_literal: true

module DefraRubyGovpay
  # Base class for handling GovPay webhook jobs
  # This is a placeholder class that will be extended by applications
  # to process GovPay webhook notifications
  class GovpayWebhookJob
    def self.process_payment_webhook(webhook_body)
      GovpayWebhookPaymentService.run(webhook_body)
    end

    def self.process_refund_webhook(webhook_body)
      GovpayWebhookRefundService.run(webhook_body)
    end
  end
end
