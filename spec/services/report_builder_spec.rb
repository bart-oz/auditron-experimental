# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReportBuilder do
  describe ".call" do
    subject(:report) { JSON.parse(described_class.call(result), symbolize_names: true) }

    let(:result) do
      TransactionMatcher::Result.new(
        matched: [{ id: "TXN001", amount: 100.0 }],
        bank_only: [{ id: "TXN002", amount: 50.0 }],
        processor_only: [{ id: "TXN003", amount: 75.0 }],
        discrepancies: [
          { id: "TXN004", bank_amount: 100.0, processor_amount: 99.5, difference: 0.5 }
        ]
      )
    end

    it "includes summary with correct counts" do
      expect(report[:summary]).to eq(
        matched: 1,
        bank_only: 1,
        processor_only: 1,
        discrepancies: 1
      )
    end

    it "includes bank_only_ids" do
      expect(report[:bank_only_ids]).to eq(["TXN002"])
    end

    it "includes processor_only_ids" do
      expect(report[:processor_only_ids]).to eq(["TXN003"])
    end

    it "includes discrepancy details" do
      expect(report[:discrepancy_details]).to eq([
                                                   {
                                                     transaction_id: "TXN004",
                                                     bank_amount: 100.0,
                                                     processor_amount: 99.5,
                                                     difference: 0.5
                                                   }
                                                 ])
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

      it "returns empty collections" do
        expect(report[:summary]).to eq(matched: 0, bank_only: 0, processor_only: 0, discrepancies: 0)
        expect(report[:bank_only_ids]).to eq([])
        expect(report[:processor_only_ids]).to eq([])
        expect(report[:discrepancy_details]).to eq([])
      end
    end
  end
end
