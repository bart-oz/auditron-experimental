# frozen_string_literal: true

module Reconciliations
  class Process
    include Interactor::Organizer

    organize SetProcessingStatus,
             ParseBankFile,
             ParseProcessorFile,
             MatchTransactions,
             BuildReport,
             CompleteReconciliation

    def call
      ActiveRecord::Base.transaction do
        super
      end
    rescue StandardError => e
      context.reconciliation.update(
        status: :failed,
        error_message: e.message
      )
    end
  end
end
