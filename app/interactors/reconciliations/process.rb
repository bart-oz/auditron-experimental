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
  end
end
