# frozen_string_literal: true

module Api
  module V1
    class ReconciliationSerializer
      def self.call(reconciliation)
        new(reconciliation).call
      end

      def initialize(reconciliation)
        @reconciliation = reconciliation
      end

      def call
        core_attributes.merge(counts).merge(file_status).merge(timestamps)
      end

      private

      attr_reader :reconciliation

      def core_attributes
        {
          id: reconciliation.id,
          status: reconciliation.status,
          error_message: reconciliation.error_message,
          processed_at: reconciliation.processed_at
        }
      end

      def counts
        {
          matched_count: reconciliation.matched_count,
          bank_only_count: reconciliation.bank_only_count,
          processor_only_count: reconciliation.processor_only_count,
          discrepancy_count: reconciliation.discrepancy_count
        }
      end

      def file_status
        {
          bank_file_attached: reconciliation.bank_file.attached?,
          processor_file_attached: reconciliation.processor_file.attached?
        }
      end

      def timestamps
        {
          created_at: reconciliation.created_at,
          updated_at: reconciliation.updated_at
        }
      end
    end
  end
end
