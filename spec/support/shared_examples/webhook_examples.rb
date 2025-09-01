# frozen_string_literal: true

RSpec.shared_examples "webhook data extraction" do |service_type|
  describe "data extraction behavior" do
    subject(:result) { described_class.run(webhook_body) }

    let(:fixture_file) do
      if service_type == :payment
        File.read("spec/fixtures/files/webhook_payment_update_body.json")
      else
        File.read("spec/fixtures/files/webhook_refund_update_body.json")
      end
    end

    let(:webhook_body) { JSON.parse(fixture_file) }

    let(:resource_id) { webhook_body["resource_id"] }
    let(:resource_status) { webhook_body.dig("resource", "state", "status") }

    it "extracts and returns the correct resource id" do
      expect(result).to include(id: resource_id)
    end

    it "extracts and returns the correct status" do
      expect(result).to include(status: resource_status)
    end
  end
end
