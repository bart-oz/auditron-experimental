# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorCodes do
  describe "ErrorCode structure" do
    subject(:error_code) { ErrorCodes::UNAUTHORIZED }

    it "has code, status, and default_message" do
      expect(error_code.code).to eq("UNAUTHORIZED")
      expect(error_code.status).to eq(:unauthorized)
      expect(error_code.default_message).to be_present
    end

    it "is immutable" do
      expect { error_code.instance_variable_set(:@code, "HACKED") }.to raise_error(FrozenError)
    end
  end

  describe "defined error codes" do
    it { expect(ErrorCodes::UNAUTHORIZED.status).to eq(:unauthorized) }
    it { expect(ErrorCodes::TOKEN_EXPIRED.status).to eq(:unauthorized) }
    it { expect(ErrorCodes::FORBIDDEN.status).to eq(:forbidden) }
    it { expect(ErrorCodes::NOT_FOUND.status).to eq(:not_found) }
    it { expect(ErrorCodes::VALIDATION_ERROR.status).to eq(:unprocessable_content) }
    it { expect(ErrorCodes::RATE_LIMITED.status).to eq(:too_many_requests) }
  end
end
