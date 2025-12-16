# frozen_string_literal: true

module Api
  module V1
    class ReconciliationsController < BaseController
      include Pundit::Authorization
      include Pagy::Method

      before_action :authenticate_api_key!
      before_action :set_reconciliation, only: %i[show report]

      # Rescue Pundit errors with proper error codes
      rescue_from Pundit::NotAuthorizedError do
        render_error(ErrorCodes::FORBIDDEN)
      end

      # GET /api/v1/reconciliations
      def index
        authorize Reconciliation
        @pagy, reconciliations = pagy(:offset, policy_scope(Reconciliation).recent)

        render_success({
                         reconciliations: reconciliations.map { |r| ReconciliationSerializer.call(r) },
                         pagination: @pagy.data_hash
                       })
      end

      # GET /api/v1/reconciliations/:id
      def show
        authorize @reconciliation
        render_success({ reconciliation: ReconciliationSerializer.call(@reconciliation) })
      end

      # GET /api/v1/reconciliations/:id/report
      def report
        authorize @reconciliation, :show?

        if @reconciliation.completed? && @reconciliation.report.present?
          render plain: @reconciliation.report, content_type: "text/markdown"
        else
          render_error(ErrorCodes::NOT_FOUND, message: "Report not available yet")
        end
      end

      # POST /api/v1/reconcile
      def create
        reconciliation = current_user.reconciliations.build(reconciliation_params)
        authorize reconciliation

        if reconciliation.save
          # Enqueue processing job if both files are attached
          ReconciliationJob.perform_later(reconciliation.id) if reconciliation.files_attached?

          render_success({ reconciliation: ReconciliationSerializer.call(reconciliation) }, status: :created)
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
    end
  end
end
