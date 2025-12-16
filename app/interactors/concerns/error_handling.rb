# frozen_string_literal: true

module ErrorHandling
  extend ActiveSupport::Concern

  # Fail the interactor with a structured error code
  def fail_with!(error_code, message: nil, details: nil)
    context.fail!(
      error_code:,
      error_message: message || error_code.default_message,
      error_details: details
    )
  end
end
