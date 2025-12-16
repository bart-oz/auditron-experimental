# frozen_string_literal: true

module Api
  module V1
    class ReconciliationsController < BaseController
      include Pundit::Authorization

      before_action :authenticate_api_key!
      before_action :set_reconciliation, only: [:show]

      # Rescue Pundit errors with proper error codes
      rescue_from Pundit::NotAuthorizedError do
        render_error(ErrorCodes::FORBIDDEN)
      end

      # GET /api/v1/reconciliations
      def index
        authorize Reconciliation
        reconciliations = policy_scope(Reconciliation).recent
        render_success({ reconciliations: reconciliations.map { |r| serialize_reconciliation(r) } })
      end

      # GET /api/v1/reconciliations/:id
      def show
        authorize @reconciliation
        render_success({ reconciliation: serialize_reconciliation(@reconciliation) })
      end

      # POST /api/v1/reconciliations
      def create
        reconciliation = current_user.reconciliations.build(reconciliation_params)
        authorize reconciliation

        if reconciliation.save
          # Enqueue processing job if both files are attached
          ReconciliationJob.perform_later(reconciliation.id) if reconciliation.files_attached?

          render_success({ reconciliation: serialize_reconciliation(reconciliation) }, status: :created)
        else
          render_error(
            ErrorCodes::VALIDATION_ERROR,
            message: "Validation failed",
            details: { errors: reconciliation.errors.full_messages }
          )
        end
      end

      private

      def set_reconciliation
        @reconciliation = current_user.reconciliations.find_by(id: params[:id])
        render_error(ErrorCodes::NOT_FOUND) unless @reconciliation
      end

      def reconciliation_params
        params.expect(reconciliation: %i[status bank_file processor_file])
      end

      def pundit_user
        current_user
      end

      # Simple serializer - will be replaced with Blueprinter later
      def serialize_reconciliation(reconciliation)
        {
          id: reconciliation.id,
          status: reconciliation.status,
          matched_count: reconciliation.matched_count,
          bank_only_count: reconciliation.bank_only_count,
          processor_only_count: reconciliation.processor_only_count,
          discrepancy_count: reconciliation.discrepancy_count,
          error_message: reconciliation.error_message,
          processed_at: reconciliation.processed_at,
          bank_file_attached: reconciliation.bank_file.attached?,
          processor_file_attached: reconciliation.processor_file.attached?,
          created_at: reconciliation.created_at,
          updated_at: reconciliation.updated_at
        }
      end
    end
  end
end
