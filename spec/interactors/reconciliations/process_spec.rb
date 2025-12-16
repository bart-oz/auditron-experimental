# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reconciliations::Process do
  describe ".call" do
    let(:reconciliation) { create(:reconciliation, :processing) }
    let(:bank_transactions) { [{ id: "TXN001", amount: 100.0 }] }
    let(:processor_transactions) { [{ id: "TXN001", amount: 100.0 }] }
    let(:match_result) do
      TransactionMatcher::Result.new(
        matched: [{ id: "TXN001" }],
        bank_only: [],
        processor_only: [],
        discrepancies: []
      )
    end

    before do
      reconciliation.bank_file.attach(
        io: StringIO.new("date,amount\n2025-01-01,100.00"),
        filename: "bank.csv",
        content_type: "text/csv"
      )
      reconciliation.processor_file.attach(
        io: StringIO.new('[{"id": "TXN001", "amount": 100.0}]'),
        filename: "processor.json",
        content_type: "application/json"
      )

      allow(BankFileParser).to receive(:call).and_return(bank_transactions)
      allow(ProcessorFileParser).to receive(:call).and_return(processor_transactions)
      allow(TransactionMatcher).to receive(:call).and_return(match_result)
    end

    it "processes reconciliation through all steps" do
      result = described_class.call(reconciliation:)

      expect(result).to be_success
      expect(reconciliation.reload).to be_completed
    end

    it "calls all services in order" do
      described_class.call(reconciliation:)

      expect(BankFileParser).to have_received(:call)
      expect(ProcessorFileParser).to have_received(:call)
      expect(TransactionMatcher).to have_received(:call)
    end

    context "when bank file parsing fails" do
      before do
        allow(BankFileParser).to receive(:call).and_raise(
          BankFileParser::ParseError, "Invalid CSV"
        )
      end

      it "fails with error" do
        result = described_class.call(reconciliation:)

        expect(result).to be_failure
        expect(result.error_code).to eq(ErrorCodes::VALIDATION_ERROR)
      end

      it "does not call subsequent services" do
        described_class.call(reconciliation:)

        expect(ProcessorFileParser).not_to have_received(:call)
        expect(TransactionMatcher).not_to have_received(:call)
      end
    end
  end
end
