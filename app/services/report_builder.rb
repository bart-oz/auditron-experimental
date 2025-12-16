# frozen_string_literal: true

# Builds a JSON report from TransactionMatcher results
class ReportBuilder
  def self.call(result)
    new(result).call
  end

  def initialize(result)
    @result = result
  end

  def call
    {
      summary: build_summary,
      discrepancy_details: build_discrepancy_details,
      bank_only_ids: result.bank_only.pluck(:id),
      processor_only_ids: result.processor_only.pluck(:id)
    }.to_json
  end

  private

  attr_reader :result

  def build_summary
    {
      matched: result.matched.size,
      bank_only: result.bank_only.size,
      processor_only: result.processor_only.size,
      discrepancies: result.discrepancies.size
    }
  end

  def build_discrepancy_details
    result.discrepancies.map do |disc|
      {
        transaction_id: disc[:id],
        bank_amount: disc[:bank_amount].to_f,
        processor_amount: disc[:processor_amount].to_f,
        difference: disc[:difference].to_f
      }
    end
  end
end
