# frozen_string_literal: true

module DefraRubyGovpay
  # The Refund class represents a refund object in the Govpay Integration.
  # It provides methods to check the status of a refund.
  class Refund < Object
    def success?
      status == "success"
    end

    def submitted?
      status == "submitted"
    end
  end
end
