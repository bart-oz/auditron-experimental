# frozen_string_literal: true

require "rails_helper"

RSpec.describe TransactionMatcher do
  describe ".call" do
    context "with matching transactions" do
      let(:bank_transactions) do
        [
          { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment One", status: "completed" },
          { id: "TX002", amount: BigDecimal("250.50"), date: Date.new(2023, 4, 2), description: "Payment Two", status: "completed" }
        ]
      end

      let(:processor_transactions) do
        [
          { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment One", status: "completed" },
          { id: "TX002", amount: BigDecimal("250.50"), date: Date.new(2023, 4, 2), description: "Payment Two", status: "completed" }
        ]
      end

      it "identifies matched transactions" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.matched.size).to eq(2)
        expect(result.matched.map { |m| m[:bank][:id] }).to contain_exactly("TX001", "TX002")
      end

      it "returns empty arrays for unmatched" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.bank_only).to be_empty
        expect(result.processor_only).to be_empty
        expect(result.discrepancies).to be_empty
      end
    end

    context "with amount discrepancies" do
      let(:bank_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.50"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      let(:processor_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      it "identifies amount discrepancies" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.discrepancies.size).to eq(1)
        discrepancy = result.discrepancies.first
        expect(discrepancy[:id]).to eq("TX001")
        expect(discrepancy[:types]).to eq([:amount])
        expect(discrepancy[:bank_amount]).to eq(BigDecimal("100.50"))
        expect(discrepancy[:processor_amount]).to eq(BigDecimal("100.00"))
      end

      it "does not count discrepancy as matched" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.matched).to be_empty
      end
    end

    context "with status discrepancies" do
      let(:bank_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      let(:processor_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "pending" }]
      end

      it "identifies status discrepancies" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.discrepancies.size).to eq(1)
        discrepancy = result.discrepancies.first
        expect(discrepancy[:id]).to eq("TX001")
        expect(discrepancy[:types]).to eq([:status])
        expect(discrepancy[:bank_status]).to eq("completed")
        expect(discrepancy[:processor_status]).to eq("pending")
      end
    end

    context "with both amount and status discrepancies" do
      let(:bank_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.50"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      let(:processor_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "pending" }]
      end

      it "identifies both discrepancy types" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.discrepancies.size).to eq(1)
        discrepancy = result.discrepancies.first
        expect(discrepancy[:types]).to contain_exactly(:amount, :status)
      end
    end

    context "with small amount differences within tolerance" do
      let(:bank_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.009"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      let(:processor_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      it "treats small differences as matching" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.matched.size).to eq(1)
        expect(result.discrepancies).to be_empty
      end
    end

    context "with bank-only transactions" do
      let(:bank_transactions) do
        [
          { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" },
          { id: "TX999", amount: BigDecimal("50.00"), date: Date.new(2023, 4, 3), description: "Only in bank", status: "completed" }
        ]
      end

      let(:processor_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      it "identifies bank-only transactions" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.bank_only.size).to eq(1)
        expect(result.bank_only.first[:id]).to eq("TX999")
      end
    end

    context "with processor-only transactions" do
      let(:bank_transactions) do
        [{ id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" }]
      end

      let(:processor_transactions) do
        [
          { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment", status: "completed" },
          { id: "TX888", amount: BigDecimal("75.00"), date: Date.new(2023, 4, 4), description: "Only in processor", status: "completed" }
        ]
      end

      it "identifies processor-only transactions" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.processor_only.size).to eq(1)
        expect(result.processor_only.first[:id]).to eq("TX888")
      end
    end

    context "with mixed results using fixture data" do
      # Simulating the fixture files:
      # Bank: TX001, TX002, TX003, TX004
      # Processor: TX001, TX002, TX003, TX005
      # TX003 has amount discrepancy (75.25 in bank, 75.00 in processor)
      let(:bank_transactions) do
        [
          { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment One", status: "completed" },
          { id: "TX002", amount: BigDecimal("250.50"), date: Date.new(2023, 4, 2), description: "Payment Two", status: "completed" },
          { id: "TX003", amount: BigDecimal("75.25"), date: Date.new(2023, 4, 3), description: "Payment Three", status: "pending" },
          { id: "TX004", amount: BigDecimal("500.00"), date: Date.new(2023, 4, 4), description: "Bank Only", status: "completed" }
        ]
      end

      let(:processor_transactions) do
        [
          { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment One", status: "completed" },
          { id: "TX002", amount: BigDecimal("250.50"), date: Date.new(2023, 4, 2), description: "Payment Two", status: "completed" },
          { id: "TX003", amount: BigDecimal("75.00"), date: Date.new(2023, 4, 3), description: "Payment Three", status: "pending" },
          { id: "TX005", amount: BigDecimal("150.00"), date: Date.new(2023, 4, 5), description: "Processor Only", status: "completed" }
        ]
      end

      it "returns correct counts for all categories" do
        result = described_class.call(bank_transactions:, processor_transactions:)

        expect(result.matched.size).to eq(2) # TX001, TX002
        expect(result.discrepancies.size).to eq(1)    # TX003
        expect(result.bank_only.size).to eq(1)        # TX004
        expect(result.processor_only.size).to eq(1)   # TX005
      end
    end
  end
end
