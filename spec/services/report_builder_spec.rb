# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportBuilder do
  describe ".call" do
    subject(:report) { described_class.call(result) }

    let(:result) do
      TransactionMatcher::Result.new(
        matched: [{ id: "TXN001", amount: BigDecimal("100.0") }],
        bank_only: [{ id: "TXN002", amount: BigDecimal("50.0"), status: "completed", description: "Bank payment" }],
        processor_only: [{ id: "TXN003", amount: BigDecimal("75.0"), status: "pending", description: "Processor payment" }],
        discrepancies: [
          {
            id: "TXN004",
            types: %i[amount status],
            bank_amount: BigDecimal("100.0"),
            processor_amount: BigDecimal("99.5"),
            amount_difference: BigDecimal("0.5"),
            bank_status: "completed",
            processor_status: "pending"
          }
        ]
      )
    end

    it "generates a Markdown report" do
      expect(report).to be_a(String)
      expect(report).to include("# Payment Reconciliation Report")
    end

    it "includes summary with correct counts" do
      expect(report).to include("| ✅ Matched | 1 |")
      expect(report).to include("| ⚠️ Discrepancies | 1 |")
      expect(report).to include("| 🏦 Bank Only | 1 |")
      expect(report).to include("| 💳 Processor Only | 1 |")
    end

    it "includes discrepancy details with types" do
      expect(report).to include("## Discrepancies")
      expect(report).to include("TXN004")
      expect(report).to include("amount, status")
      expect(report).to include("$100.0 vs $99.5")
      expect(report).to include("completed vs pending")
    end

    it "includes bank-only transactions" do
      expect(report).to include("## Bank Only Transactions")
      expect(report).to include("TXN002")
      expect(report).to include("$50.0")
    end

    it "includes processor-only transactions" do
      expect(report).to include("## Processor Only Transactions")
      expect(report).to include("TXN003")
      expect(report).to include("$75.0")
    end

    context "with empty result" do
      let(:result) do
        TransactionMatcher::Result.new(
          matched: [],
          bank_only: [],
          processor_only: [],
          discrepancies: []
        )
      end

      it "returns summary with zero counts" do
        expect(report).to include("| ✅ Matched | 0 |")
        expect(report).to include("| ⚠️ Discrepancies | 0 |")
      end

      it "omits empty sections" do
        expect(report).not_to include("## Discrepancies")
        expect(report).not_to include("## Bank Only Transactions")
        expect(report).not_to include("## Processor Only Transactions")
      end
    end

    context "with amount-only discrepancy" do
      let(:result) do
        TransactionMatcher::Result.new(
          matched: [],
          bank_only: [],
          processor_only: [],
          discrepancies: [
            {
              id: "TXN005",
              types: [:amount],
              bank_amount: BigDecimal("100.0"),
              processor_amount: BigDecimal("95.0"),
              amount_difference: BigDecimal("5.0"),
              bank_status: "completed",
              processor_status: "completed"
            }
          ]
        )
      end

      it "shows amount discrepancy with dash for status" do
        expect(report).to include("TXN005")
        expect(report).to include("$100.0 vs $95.0")
        expect(report).to include("| — |")
      end
    end

    context "with status-only discrepancy" do
      let(:result) do
        TransactionMatcher::Result.new(
          matched: [],
          bank_only: [],
          processor_only: [],
          discrepancies: [
            {
              id: "TXN006",
              types: [:status],
              bank_amount: BigDecimal("100.0"),
              processor_amount: BigDecimal("100.0"),
              amount_difference: BigDecimal("0"),
              bank_status: "completed",
              processor_status: "pending"
            }
          ]
        )
      end

      it "shows status discrepancy with dash for amount" do
        expect(report).to include("TXN006")
        expect(report).to include("| — |")
        expect(report).to include("completed vs pending")
      end
    end
  end
end
