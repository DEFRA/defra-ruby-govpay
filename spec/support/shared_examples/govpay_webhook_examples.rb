# frozen_string_literal: true

RSpec.shared_examples "govpay webhook data extraction" do |service_type|
  describe "data extraction behavior" do
    let(:fixture_file) do
      if service_type == :payment
        File.read("spec/fixtures/files/webhook_payment_update_body.json")
      else
        File.read("spec/fixtures/files/webhook_refund_update_body.json")
      end
    end

    let(:webhook_body) { JSON.parse(fixture_file) }

    let(:resource_id) do
      if service_type == :payment
        webhook_body.dig("resource", "payment_id")
      else
        webhook_body["refund_id"]
      end
    end

    let(:resource_status) do
      if service_type == :payment
        webhook_body.dig("resource", "state", "status")
      else
        webhook_body["status"]
      end
    end

    it "extracts and returns the correct data" do
      result = described_class.run(webhook_body)

      # For refunds, the service returns the payment_id from the webhook, not the refund_id
      expected_id = if service_type == :refund
                     webhook_body["payment_id"]
                   else
                     resource_id
                   end

      expect(result).to include(
        payment_id: expected_id,
        status: resource_status
      )
    end

    it "includes service type in the result" do
      result = described_class.run(webhook_body)

      expected_service_type = webhook_body.dig("resource", "moto") ? "back_office" : "front_office"

      expect(result).to include(service_type: expected_service_type)
    end
  end
end
