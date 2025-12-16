# frozen_string_literal: true

require "rails_helper"

RSpec.describe ErrorHandling do
  # Create a test interactor that includes the concern
  let(:test_interactor_class) do
    Class.new do
      include Interactor
      include ErrorHandling

      def call
        fail_with!(ErrorCodes::VALIDATION_ERROR, message: context.message, details: context.details)
      end
    end
  end

  describe "#fail_with!" do
    it "fails the context with error_code" do
      result = test_interactor_class.call

      expect(result).to be_failure
      expect(result.error_code).to eq(ErrorCodes::VALIDATION_ERROR)
    end

    it "uses custom message when provided" do
      result = test_interactor_class.call(message: "Custom error")

      expect(result.error_message).to eq("Custom error")
    end

    it "uses default message when none provided" do
      result = test_interactor_class.call

      expect(result.error_message).to eq("Validation failed")
    end

    it "includes details when provided" do
      result = test_interactor_class.call(details: { field: "name" })

      expect(result.error_details).to eq({ field: "name" })
    end
  end
end
