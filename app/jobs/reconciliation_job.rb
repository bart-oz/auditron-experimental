# frozen_string_literal: true

# Background job to process reconciliation files
# Parses bank and processor files, matches transactions, and updates counts
class ReconciliationJob < ApplicationJob
  queue_as :default
  retry_on ActiveStorage::FileNotFoundError, wait: :polynomially_longer, attempts: 3
  discard_on BankFileParser::ParseError, ProcessorFileParser::ParseError

  def perform(reconciliation_id)
    reconciliation = Reconciliation.find(reconciliation_id)

    return unless reconciliation.pending?
    return unless reconciliation.files_attached?

    process_reconciliation(reconciliation)
  rescue ActiveRecord::RecordNotFound
    Rails.logger.warn("Reconciliation #{reconciliation_id} not found")
    raise
  rescue StandardError => e
    handle_failure(reconciliation, e) if reconciliation
    raise
  end

  private

  def process_reconciliation(reconciliation)
    reconciliation.processing!

    bank_transactions = BankFileParser.call(reconciliation.bank_file)
    processor_transactions = ProcessorFileParser.call(reconciliation.processor_file)

    result = TransactionMatcher.call(
      bank_transactions:,
      processor_transactions:
    )

    save_reconciliation_results(reconciliation, result)
  end

  def save_reconciliation_results(reconciliation, result)
    reconciliation.assign_attributes(build_result_attributes(result))
    reconciliation.save!(validate: false)
  end

  def build_result_attributes(result)
    {
      status: :completed,
      matched_count: result.matched.size,
      bank_only_count: result.bank_only.size,
      processor_only_count: result.processor_only.size,
      discrepancy_count: result.discrepancies.size,
      report: ReportBuilder.call(result),
      processed_at: Time.current
    }
  end

  def handle_failure(reconciliation, error)
    reconciliation.assign_attributes(
      status: :failed,
      error_message: error.message,
      processed_at: Time.current
    )
    reconciliation.save!(validate: false)

    Rails.logger.error("Reconciliation #{reconciliation.id} failed: #{error.message}")
  end
end
