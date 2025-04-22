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

The gem provides functionality for handling Govpay webhooks for both payments and refunds. The webhook services validate the webhook content, that the status transition is allowed, return structured information that your application can use to update its records.

### Processing Webhooks

The webhook services extract and return data from the webhook payload:

```ruby
# For payment webhooks
result = DefraRubyGovpay::GovpayWebhookPaymentService.run(webhook_body)
# => { id: "hu20sqlact5260q2nanm0q8u93", status: "success" }

# For refund webhooks
result = DefraRubyGovpay::GovpayWebhookRefundService.run(webhook_body)
# => { id: "789", payment_id: "original-payment-123", status: "success" }
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
