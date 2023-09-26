# frozen_string_literal: true

module DefraRubyGovpay
  # The Payment class represents a payment object in the Govpay Integration.
  # It contains methods to check refund status and details about the payment.
  class Payment < Object
    def refundable?(amount_requested = 0)
      refund.status == "available" &&
        refund.amount_available > refund.amount_submitted &&
        amount_requested <= refund.amount_available
    end

    def refund
      refund_summary
    end
  end
end
