module GovpayIntegration
  class Refund < Object
    def success?
      status == "success"
    end

    def submitted?
      status == "submitted"
    end
  end
end
