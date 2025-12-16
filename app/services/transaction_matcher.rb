# frozen_string_literal: true

# Matches transactions from bank and processor files
class TransactionMatcher
  AMOUNT_TOLERANCE = BigDecimal("0.01") # Allow 1 cent variance for rounding

  Result = Struct.new(:matched, :bank_only, :processor_only, :discrepancies, keyword_init: true)

  def self.call(bank_transactions:, processor_transactions:)
    new(bank_transactions, processor_transactions).call
  end

  def initialize(bank_transactions, processor_transactions)
    @bank_transactions = bank_transactions
    @processor_transactions = processor_transactions
    @results = { matched: [], bank_only: [], processor_only: [], discrepancies: [] }
  end

  def call
    match_transactions
    build_result
  end

  private

  def match_transactions
    processor_by_id = @processor_transactions.index_by { |tx| tx[:id] }

    @bank_transactions.each do |bank_tx|
      processor_tx = processor_by_id.delete(bank_tx[:id])
      classify_transaction(bank_tx, processor_tx)
    end

    # Remaining processor transactions are processor-only
    @results[:processor_only] = processor_by_id.values
  end

  def classify_transaction(bank_tx, processor_tx)
    return @results[:bank_only] << bank_tx unless processor_tx

    discrepancy = build_discrepancy(bank_tx, processor_tx)

    if discrepancy[:types].empty?
      @results[:matched] << { bank: bank_tx, processor: processor_tx }
    else
      @results[:discrepancies] << discrepancy
    end
  end

  def build_discrepancy(bank_tx, processor_tx)
    bank_amount = bank_tx[:amount]
    processor_amount = processor_tx[:amount]

    types = []
    types << :amount unless amounts_match?(bank_amount, processor_amount)
    types << :status unless statuses_match?(bank_tx[:status], processor_tx[:status])

    {
      id: bank_tx[:id],
      types:,
      bank_amount:,
      processor_amount:,
      amount_difference: (bank_amount - processor_amount).abs,
      bank_status: bank_tx[:status],
      processor_status: processor_tx[:status]
    }
  end

  def build_result
    Result.new(**@results)
  end

  def amounts_match?(bank_amount, processor_amount)
    (bank_amount - processor_amount).abs <= AMOUNT_TOLERANCE
  end

  def statuses_match?(bank_status, processor_status)
    bank_status == processor_status
  end
end
