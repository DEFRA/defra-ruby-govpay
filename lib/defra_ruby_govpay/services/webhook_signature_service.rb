# frozen_string_literal: true

module DefraRubyGovpay
  class WebhookSignatureService
    class DigestFailure < StandardError; end

    def self.run(body:)
      new.run(body: body)
    end

    def run(body:)
      generate_signatures(body.to_s)
    rescue StandardError => e
      DefraRubyGovpay.logger.error "Payment webhook signature generation failed: #{e}"
      raise DigestFailure, e
    end

    private

    def generate_signatures(body)
      {
        front_office: hmac_digest(body, front_office_secret),
        back_office: hmac_digest(body, back_office_secret)
      }
    end

    def front_office_secret
      DefraRubyGovpay.configuration.front_office_webhook_signing_secret
    end

    def back_office_secret
      DefraRubyGovpay.configuration.back_office_webhook_signing_secret
    end

    def hmac_digest(body, secret)
      digest = OpenSSL::Digest.new("sha256")
      OpenSSL::HMAC.hexdigest(digest, secret, body)
    end
  end
end
