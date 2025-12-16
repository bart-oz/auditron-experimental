# frozen_string_literal: true

# Background job to process reconciliation files
# Delegates to Reconciliations::Process organizer
class ReconciliationJob < ApplicationJob
  queue_as :default
  retry_on ActiveStorage::FileNotFoundError, wait: :polynomially_longer, attempts: 3
  discard_on BankFileParser::ParseError, ProcessorFileParser::ParseError

  def perform(reconciliation_id)
    reconciliation = Reconciliation.find(reconciliation_id)

    return unless reconciliation.pending?
    return unless reconciliation.files_attached?

    result = Reconciliations::Process.call(reconciliation:)

    handle_failure(reconciliation, result.error_message) if result.failure?
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Reconciliation #{reconciliation_id} not found")
    raise
  end

  private

  def handle_failure(reconciliation, error_message)
    reconciliation.assign_attributes(
      status: :failed,
      error_message:,
      processed_at: Time.current
    )
    reconciliation.save!(validate: false)

    Rails.logger.error("Reconciliation #{reconciliation.id} failed: #{error_message}")
  end
end
