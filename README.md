# Defra Ruby Govpay Ruby Gem

The `defra-ruby-govpay` gem facilitates seamless integration with GovPay services, specifically tailored for DEFRA's WCR and WEX applications. It aims to abstract the integration code, offering a flexible and adaptable solution that requires minimal assumptions about the application's data models.

## Table of Contents

1. [Installation](#installation)
2. [Configuration](#configuration)
3. [Usage](#usage)
4. [Webhook Handling](#webhook-handling)
5. [Error Handling](#error-handling)
6. [Testing](#testing)

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'defra-ruby-govpay'
```
And then execute
```sh
bundle install
```

Or install it yourself as:
```sh
gem install defra-ruby-govpay
```

## Configuration

Before you start using the gem, you need to configure it according to your requirements. Create an initializer file (e.g., `config/initializers/govpay.rb`) and set the necessary parameters:

```ruby
DefraRubyGovpay.configure do |config|
  config.govpay_url = 'https://your-govpay-url.com'
  config.govpay_front_office_api_token = 'your-front-office-token'
  config.govpay_back_office_api_token = 'your-back-office-token'
  # ... any other configurations
end
```

## Usage

Here is a detailed guide on how to use the various components of the `defra-ruby-govpay` gem in your application:

## Sending a Request

You can send requests to the GovPay API using the `send_request` method. Here's an example:

After having followed the configuration step, create an API instance. This has a mandatory parameter to indicate
whether the host is a back-office application, in which case any payments it creates will be flagged as MOTO.
```ruby
govpay_api = DefraRubyGovpay::API.new(host_is_back_office: false)

begin
  response = govpay_api.send_request(
    method: :get,
    path: '/path/to/endpoint',
    params: { param1: 'value1', param2: 'value2' },
    is_moto: false
  )
  puts "Response received: #{response}"
rescue DefraRubyGovpay::GovpayApiError => e
  puts "An error occurred: #{e.message}"
end
```

## Error Handling

Errors are handled through the DefraRubyGovpay::GovpayApiError class. Here's an example of how you can handle errors:
```ruby
begin
  # some code that might raise an error
rescue DefraRubyGovpay::GovpayApiError => e
  puts "An error occurred: #{e.message}"
end
```

## Webhook Handling

The gem provides functionality for handling Gov.UK Pay webhooks for both payments and refunds. The webhook services process the webhook data and return structured information that your application can use to update its records.

### Processing Webhooks

The webhook services extract and return data from the webhook payload:

```ruby
# For payment webhooks
result = DefraRubyGovpay::GovpayWebhookPaymentService.run(webhook_body)
# => { id: "hu20sqlact5260q2nanm0q8u93", status: "success" }

# For refund webhooks
result = DefraRubyGovpay::GovpayWebhookRefundService.run(webhook_body)
# => { id: "789", payment_id: "original-payment-123", status: "success", amount: 2000, created_date: "2022-01-26T16:52:41.178Z" }
```

Your application should create webhook handler classes that use these services to process webhooks. The handlers should:

1. Call the appropriate webhook service to extract data
2. Find the relevant payment or refund in your application
3. Update the status of the payment or refund
4. Perform any additional application-specific logic

This approach keeps the webhook handling logic clean and maintainable, with a clear separation of concerns between the gem and your application.

# app/jobs/your_app/govpay_webhook_job.rb
module YourApp
  class GovpayWebhookJob < ApplicationJob
    def perform(webhook_body)
      if webhook_body["resource_type"]&.downcase == "payment"
        process_payment_webhook(webhook_body)
      elsif webhook_body["refund_id"].present?
        process_refund_webhook(webhook_body)
      else
        raise ArgumentError, "Unrecognised Govpay webhook type"
      end
    rescue StandardError => e
      # Handle errors
    end

    private

    def process_payment_webhook(webhook_body)
      result = GovpayPaymentHandler.process(webhook_body)
      Rails.logger.info "Processed payment webhook for payment_id: #{result[:payment_id]}, status: #{result[:status]}"
    end

    def process_refund_webhook(webhook_body)
      result = GovpayRefundHandler.process(webhook_body)
      Rails.logger.info "Processed refund webhook for refund_id: #{result[:payment_id]}, status: #{result[:status]}"
    end
  end
end
```

### Validating Webhook Signatures

To validate the signature of a webhook, use the `CallbackValidator` class:

```ruby
valid = DefraRubyGovpay::CallbackValidator.call(
  request_body,
  ENV['GOVPAY_WEBHOOK_SIGNING_SECRET'],
  request.headers['Pay-Signature']
)

if valid
  # Process the webhook
else
  # Handle invalid signature
end
```

### Payment vs Refund Webhooks

The gem can handle both payment and refund webhooks:

- **Payment Webhooks**: These have a `resource_type` of "payment" and contain payment status information in `resource.state.status`.
- **Refund Webhooks**: These have a `refund_id` field and contain refund status information in the `status` field.

The appropriate service class will be used based on the webhook type:

- `GovpayWebhookPaymentService` for payment webhooks
- `GovpayWebhookRefundService` for refund webhooks

## Testing

```
bundle exec rspec
```
