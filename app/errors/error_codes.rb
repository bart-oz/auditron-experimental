# frozen_string_literal: true

# Centralized error codes for consistent API responses
# Usage: render_error(ErrorCodes::UNAUTHORIZED)
module ErrorCodes
  ErrorCode = Data.define(:code, :status, :default_message)

  # Authentication (401)
  UNAUTHORIZED = ErrorCode.new(
    code: "UNAUTHORIZED",
    status: :unauthorized,
    default_message: "Invalid or missing authentication token"
  )

  TOKEN_EXPIRED = ErrorCode.new(
    code: "TOKEN_EXPIRED",
    status: :unauthorized,
    default_message: "Authentication token has expired"
  )

  # Authorization (403)
  FORBIDDEN = ErrorCode.new(
    code: "FORBIDDEN",
    status: :forbidden,
    default_message: "You do not have permission to perform this action"
  )

  # Not found (404)
  NOT_FOUND = ErrorCode.new(
    code: "NOT_FOUND",
    status: :not_found,
    default_message: "Resource not found"
  )

  # Validation (422)
  VALIDATION_ERROR = ErrorCode.new(
    code: "VALIDATION_ERROR",
    status: :unprocessable_content,
    default_message: "Validation failed"
  )
end
