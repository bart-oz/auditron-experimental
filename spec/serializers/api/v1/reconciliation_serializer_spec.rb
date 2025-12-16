# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V1::ReconciliationSerializer do
  describe ".call" do
    subject(:result) { described_class.call(reconciliation) }

    let(:reconciliation) { create(:reconciliation, :completed) }

    it "returns a hash with all expected keys" do
      expect(result.keys).to contain_exactly(
        :id, :status, :matched_count, :bank_only_count, :processor_only_count,
        :discrepancy_count, :error_message, :processed_at, :bank_file_attached,
        :processor_file_attached, :created_at, :updated_at
      )
    end

    it "serializes reconciliation attributes" do
      expect(result[:id]).to eq(reconciliation.id)
      expect(result[:status]).to eq("completed")
      expect(result[:matched_count]).to eq(100)
    end

    it "returns false for file attachment status when no files attached" do
      expect(result[:bank_file_attached]).to be false
      expect(result[:processor_file_attached]).to be false
    end

    context "with files attached" do
      before do
        reconciliation.bank_file.attach(
          io: StringIO.new("date,amount\n2025-01-01,100.00"),
          filename: "bank.csv",
          content_type: "text/csv"
        )
        reconciliation.processor_file.attach(
          io: StringIO.new("date,amount\n2025-01-01,100.00"),
          filename: "processor.csv",
          content_type: "text/csv"
        )
      end

      it "returns true for file attachment status" do
        expect(result[:bank_file_attached]).to be true
        expect(result[:processor_file_attached]).to be true
      end
    end
  end
end
