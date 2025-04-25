# frozen_string_literal: true

RSpec.shared_examples "govpay status transitions" do
  let(:service_class) { described_class }
  let(:resource_type) { service_class == DefraRubyGovpay::GovpayWebhookPaymentService ? :payment : :refund }

  let(:fixture_file) do
    if resource_type == :payment
      File.read("spec/fixtures/files/webhook_payment_update_body.json")
    else
      File.read("spec/fixtures/files/webhook_refund_update_body.json")
    end
  end

  let(:webhook_body) { JSON.parse(fixture_file) }

  def update_webhook_status(status)
    if resource_type == :payment
      webhook_body["resource"]["state"]["status"] = status
    else
      webhook_body["status"] = status
    end
  end

  describe "status transition validation" do
    context "when status hasn't changed" do
      # rubocop:disable RSpec/NoExpectationExample
      it "logs a warning but doesn't raise an error" do
        allow(DefraRubyGovpay.logger).to receive(:warn)
        run_and_expect_warning_for_unchanged_status
      end

      # rubocop:enable RSpec/NoExpectationExample

      def run_and_expect_warning_for_unchanged_status
        current_status = if resource_type == :payment
                           webhook_body.dig("resource", "state", "status")
                         else
                           webhook_body["status"]
                         end

        service_class.run(webhook_body, previous_status: current_status)
        expect(DefraRubyGovpay.logger).to have_received(:warn).with(/Status .* unchanged/)
      end
    end
  end
end

RSpec.shared_examples "a valid transition" do |old_status, new_status|
  let(:service_class) { described_class }
  let(:resource_type) { service_class == DefraRubyGovpay::GovpayWebhookPaymentService ? :payment : :refund }

  let(:fixture_file) do
    if resource_type == :payment
      File.read("spec/fixtures/files/webhook_payment_update_body.json")
    else
      File.read("spec/fixtures/files/webhook_refund_update_body.json")
    end
  end

  let(:webhook_body) { JSON.parse(fixture_file) }

  def update_webhook_status(status)
    if resource_type == :payment
      webhook_body["resource"]["state"]["status"] = status
    else
      webhook_body["status"] = status
    end
  end

  it "allows transition from #{old_status} to #{new_status}" do
    update_webhook_status(new_status)
    expect { service_class.run(webhook_body, previous_status: old_status) }.not_to raise_error
  end
end

RSpec.shared_examples "an invalid transition" do |old_status, new_status|
  let(:service_class) { described_class }
  let(:resource_type) { service_class == DefraRubyGovpay::GovpayWebhookPaymentService ? :payment : :refund }

  let(:fixture_file) do
    if resource_type == :payment
      File.read("spec/fixtures/files/webhook_payment_update_body.json")
    else
      File.read("spec/fixtures/files/webhook_refund_update_body.json")
    end
  end

  let(:webhook_body) { JSON.parse(fixture_file) }

  def update_webhook_status(status)
    if resource_type == :payment
      webhook_body["resource"]["state"]["status"] = status
    else
      webhook_body["status"] = status
    end
  end

  it "rejects transition from #{old_status} to #{new_status}" do
    update_webhook_status(new_status)
    expect { service_class.run(webhook_body, previous_status: old_status) }.to raise_error(
      DefraRubyGovpay::GovpayWebhookBaseService::InvalidGovpayStatusTransition,
      /Invalid .* status transition from #{old_status} to #{new_status}/
    )
  end
end

RSpec.shared_examples "valid and invalid transitions" do |old_status, valid_statuses, invalid_statuses = []|
  context "with previous status '#{old_status}'" do
    valid_statuses.each do |new_status|
      it_behaves_like "a valid transition", old_status, new_status
    end

    invalid_statuses.each do |new_status|
      it_behaves_like "an invalid transition", old_status, new_status
    end
  end
end

RSpec.shared_examples "no valid transitions" do |old_status|
  all_statuses = %w[created started submitted success failed cancelled error]
  it_behaves_like "valid and invalid transitions", old_status, [], all_statuses - [old_status]
end
