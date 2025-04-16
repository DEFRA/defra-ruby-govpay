# frozen_string_literal: true

RSpec.shared_examples "govpay webhook block yielding" do |service_type|
  # These shared examples focus specifically on testing the block yielding behavior
  # which is common to both payment and refund webhook services
  
  describe "block yielding behavior" do
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
    
    it "yields the extracted data to the block" do
      yielded_data = nil
      
      described_class.run(webhook_body) do |data|
        yielded_data = data
      end
      
      expect(yielded_data).to include(
        id: resource_id,
        status: resource_status,
        webhook_body: webhook_body
      )
    end
    
    it "processes the webhook when no block is given" do
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
  end
end
