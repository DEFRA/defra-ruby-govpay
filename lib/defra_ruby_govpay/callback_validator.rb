# frozen_string_literal: true

require "openssl"

module DefraRubyGovpay
  class CallbackValidator
    def self.call(request_body, signing_secret, pay_signature_header)
      new(request_body, signing_secret, pay_signature_header).call
    end

    attr_reader :request_body, :signing_secret, :pay_signature_header

    def initialize(request_body, signing_secret, pay_signature_header)
      @request_body = request_body
      @signing_secret = signing_secret
      @pay_signature_header = pay_signature_header
    end

    def call
      hmac = OpenSSL::HMAC.hexdigest("sha256", signing_secret.encode("utf-8"), request_body.encode("utf-8"))

      hmac == pay_signature_header
    end
  end
end
