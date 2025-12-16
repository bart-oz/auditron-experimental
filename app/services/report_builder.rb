# frozen_string_literal: true

# Builds a Markdown reconciliation report from TransactionMatcher results
class ReportBuilder
  def self.call(result)
    new(result).call
  end

  def initialize(result)
    @result = result
  end

  def call
    [
      header,
      summary_section,
      discrepancies_section,
      bank_only_section,
      processor_only_section
    ].compact.join("\n")
  end

  private

  attr_reader :result

  def header
    <<~MD
      # Payment Reconciliation Report

      _Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S UTC')}_

    MD
  end

  def summary_section
    <<~MD
      ## Summary

      | Metric | Count |
      |--------|------:|
      | ✅ Matched | #{result.matched.size} |
      | ⚠️ Discrepancies | #{result.discrepancies.size} |
      | 🏦 Bank Only | #{result.bank_only.size} |
      | 💳 Processor Only | #{result.processor_only.size} |

    MD
  end

  def discrepancies_section
    return nil if result.discrepancies.empty?

    rows = result.discrepancies.map { |disc| format_discrepancy_row(disc) }.join("\n")

    <<~MD
      ## Discrepancies

      | Transaction ID | Type | Amount (Bank vs Processor) | Status (Bank vs Processor) |
      |----------------|------|----------------------------|----------------------------|
      #{rows}

    MD
  end

  def format_discrepancy_row(discrepancy)
    types = discrepancy[:types].map(&:to_s).join(", ")
    amount_info = format_amount_discrepancy(discrepancy)
    status_info = format_status_discrepancy(discrepancy)
    "| #{discrepancy[:id]} | #{types} | #{amount_info} | #{status_info} |"
  end

  def format_amount_discrepancy(discrepancy)
    return "—" unless discrepancy[:types].include?(:amount)

    "$#{discrepancy[:bank_amount].to_f} vs $#{discrepancy[:processor_amount].to_f}"
  end

  def format_status_discrepancy(discrepancy)
    return "—" unless discrepancy[:types].include?(:status)

    "#{discrepancy[:bank_status]} vs #{discrepancy[:processor_status]}"
  end

  def format_transaction_row(transaction)
    "| #{transaction[:id]} | $#{transaction[:amount].to_f} | #{transaction[:status]} | #{transaction[:description]} |"
  end

  def bank_only_section
    return nil if result.bank_only.empty?

    rows = result.bank_only.map { |transaction| format_transaction_row(transaction) }.join("\n")

    <<~MD
      ## Bank Only Transactions

      _Transactions present in bank file but missing from processor._

      | Transaction ID | Amount | Status | Description |
      |----------------|-------:|--------|-------------|
      #{rows}

    MD
  end

  def processor_only_section
    return nil if result.processor_only.empty?

    rows = result.processor_only.map { |transaction| format_transaction_row(transaction) }.join("\n")

    <<~MD
      ## Processor Only Transactions

      _Transactions present in processor file but missing from bank._

      | Transaction ID | Amount | Status | Description |
      |----------------|-------:|--------|-------------|
      #{rows}

    MD
  end
end
