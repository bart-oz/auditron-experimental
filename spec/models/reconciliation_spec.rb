# frozen_string_literal: true

require "rails_helper"

RSpec.describe Reconciliation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to have_one_attached(:bank_file) }
    it { is_expected.to have_one_attached(:processor_file) }
  end

  describe "validations" do
    subject { build(:reconciliation) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to define_enum_for(:status).with_values(%w[pending processing completed failed]) }
  end

  describe "enum" do
    it "defaults to pending" do
      reconciliation = described_class.new
      expect(reconciliation.status).to eq("pending")
      expect(reconciliation).to be_pending
    end

    it "allows valid status transitions" do
      reconciliation = create(:reconciliation)
      expect(reconciliation).to be_pending

      reconciliation.processing!
      expect(reconciliation).to be_processing

      reconciliation.completed!
      expect(reconciliation).to be_completed
    end

    it "allows failed status" do
      reconciliation = create(:reconciliation, :failed)
      expect(reconciliation).to be_failed
      expect(reconciliation.error_message).to be_present
    end

    it "has all expected statuses" do
      expect(described_class.statuses.keys).to match_array(%w[pending processing completed failed])
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "orders by created_at descending" do
        old = create(:reconciliation, created_at: 2.days.ago)
        new = create(:reconciliation, created_at: 1.day.ago)

        expect(described_class.recent).to eq([new, old])
      end
    end

    describe ".by_status" do
      it "filters by pending status" do
        pending_rec = create(:reconciliation, status: :pending)
        create(:reconciliation, :completed)

        expect(described_class.by_status(:pending)).to eq([pending_rec])
      end

      it "filters by completed status" do
        create(:reconciliation, status: :pending)
        completed_rec = create(:reconciliation, :completed)

        expect(described_class.by_status(:completed)).to eq([completed_rec])
      end

      it "returns empty array for status with no records" do
        expect(described_class.by_status(:failed)).to be_empty
      end
    end
  end

  describe "factory" do
    it "creates a valid reconciliation with default pending status" do
      reconciliation = build(:reconciliation)
      expect(reconciliation).to be_valid
      expect(reconciliation).to be_pending
    end

    it "creates a valid and persisted reconciliation" do
      reconciliation = create(:reconciliation)
      expect(reconciliation).to be_persisted
    end

    it "creates completed reconciliation with trait" do
      reconciliation = build(:reconciliation, :completed)
      expect(reconciliation.status).to eq("completed")
      expect(reconciliation.matched_count).to eq(100)
      expect(reconciliation.processed_at).to be_present
    end

    it "creates failed reconciliation with trait" do
      reconciliation = build(:reconciliation, :failed)
      expect(reconciliation).to be_failed
      expect(reconciliation.error_message).to be_present
    end

    it "creates processing reconciliation with trait" do
      reconciliation = build(:reconciliation, :processing)
      expect(reconciliation).to be_processing
    end
  end
end
