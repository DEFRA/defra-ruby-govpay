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

    let(:expected_id) do
      if service_type == :refund
        webhook_body["payment_id"]
      else
        resource_id
      end
    end

    it "extracts and returns the correct data" do
      result = described_class.run(webhook_body)
      # The service returns the id (payment_id or refund_id) and status
      expect(result).to include(id: resource_id, status: resource_status)
    end

    it "includes payment_id in the result for refunds" do
      next unless service_type == :refund

      result = described_class.run(webhook_body)
      expect(result).to include(payment_id: webhook_body["payment_id"])
    end
  end
end
