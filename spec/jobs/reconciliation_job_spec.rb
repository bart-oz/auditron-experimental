# frozen_string_literal: true

require "rails_helper"

RSpec.describe ReconciliationJob do
  include ActiveJob::TestHelper

  describe "#perform" do
    let(:user) { create(:user) }
    let(:reconciliation) { create(:reconciliation, user:) }

    # Parsed data from fixture files
    let(:bank_transactions) do
      [
        { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment One", status: "completed" },
        { id: "TX002", amount: BigDecimal("250.50"), date: Date.new(2023, 4, 2), description: "Payment Two", status: "completed" },
        { id: "TX003", amount: BigDecimal("75.25"), date: Date.new(2023, 4, 3), description: "Payment Three", status: "completed" },
        { id: "TX004", amount: BigDecimal("999.99"), date: Date.new(2023, 4, 4), description: "Bank Only Transaction", status: "completed" }
      ]
    end

    let(:processor_transactions) do
      [
        { id: "TX001", amount: BigDecimal("100.00"), date: Date.new(2023, 4, 1), description: "Payment One", status: "completed" },
        { id: "TX002", amount: BigDecimal("250.50"), date: Date.new(2023, 4, 2), description: "Payment Two", status: "completed" },
        { id: "TX003", amount: BigDecimal("75.00"), date: Date.new(2023, 4, 3), description: "Payment Three Discrepancy", status: "completed" },
        { id: "TX005", amount: BigDecimal("500.00"), date: Date.new(2023, 4, 5), description: "Processor Only Transaction", status: "completed" }
      ]
    end

    context "with files attached" do
      before do
        # Stub files_attached? to return true
        allow_any_instance_of(Reconciliation).to receive(:files_attached?).and_return(true)
        # Stub the parsers to return pre-parsed data
        allow(BankFileParser).to receive(:call).and_return(bank_transactions)
        allow(ProcessorFileParser).to receive(:call).and_return(processor_transactions)
      end

      it "transitions status to processing then completed" do
        expect(reconciliation.status).to eq("pending")

        described_class.perform_now(reconciliation.id)
        reconciliation.reload

        expect(reconciliation.status).to eq("completed")
      end

      it "updates matched_count from matcher results" do
        described_class.perform_now(reconciliation.id)
        reconciliation.reload

        expect(reconciliation.matched_count).to eq(2) # TX001, TX002
      end

      it "updates bank_only_count from matcher results" do
        described_class.perform_now(reconciliation.id)
        reconciliation.reload

        expect(reconciliation.bank_only_count).to eq(1) # TX004
      end

      it "updates processor_only_count from matcher results" do
        described_class.perform_now(reconciliation.id)
        reconciliation.reload

        expect(reconciliation.processor_only_count).to eq(1) # TX005
      end

      it "updates discrepancy_count from matcher results" do
        described_class.perform_now(reconciliation.id)
        reconciliation.reload

        expect(reconciliation.discrepancy_count).to eq(1) # TX003 amount mismatch
      end

      it "generates a report" do
        described_class.perform_now(reconciliation.id)
        reconciliation.reload

        expect(reconciliation.report).to be_present
        report = JSON.parse(reconciliation.report)

        expect(report).to include("summary", "discrepancy_details", "bank_only_ids", "processor_only_ids")
      end

      it "stores discrepancy details in report" do
        described_class.perform_now(reconciliation.id)
        reconciliation.reload

        report = JSON.parse(reconciliation.report)
        discrepancy = report["discrepancy_details"].first

        expect(discrepancy["transaction_id"]).to eq("TX003")
        expect(discrepancy["bank_amount"]).to eq(75.25)
        expect(discrepancy["processor_amount"]).to eq(75.0)
      end

      it "sets processed_at timestamp" do
        freeze_time do
          described_class.perform_now(reconciliation.id)
          reconciliation.reload

          expect(reconciliation.processed_at).to eq(Time.current)
        end
      end
    end

    context "when reconciliation not found" do
      it "raises ActiveRecord::RecordNotFound" do
        expect do
          described_class.perform_now("nonexistent-uuid")
        end.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context "when reconciliation is not pending" do
      let(:completed_reconciliation) { create(:reconciliation, user:, status: :completed) }

      it "does not reprocess" do
        expect(BankFileParser).not_to receive(:call)

        described_class.perform_now(completed_reconciliation.id)
      end
    end

    context "when an error occurs during processing" do
      before do
        allow_any_instance_of(Reconciliation).to receive(:files_attached?).and_return(true)
        allow(BankFileParser).to receive(:call).and_raise(
          BankFileParser::ParseError, "Parse failed"
        )
      end

      it "transitions status to failed" do
        described_class.perform_now(reconciliation.id)

        reconciliation.reload
        expect(reconciliation.status).to eq("failed")
      end

      it "stores error message" do
        described_class.perform_now(reconciliation.id)

        reconciliation.reload
        expect(reconciliation.error_message).to include("Parse failed")
      end
    end

    context "when files are missing" do
      let(:no_files_reconciliation) { create(:reconciliation, user:) }

      it "does not process" do
        expect(BankFileParser).not_to receive(:call)

        described_class.perform_now(no_files_reconciliation.id)
      end
    end
  end

  describe "job enqueueing" do
    it "enqueues job in default queue" do
      expect do
        described_class.perform_later("test-id")
      end.to have_enqueued_job(described_class).with("test-id").on_queue("default")
    end
  end
end
