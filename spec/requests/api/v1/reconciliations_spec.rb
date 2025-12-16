# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Api::V1::Reconciliations", type: :request do
  let(:user) { create(:user) }
  let(:api_key) { create(:api_key, user:) }
  let(:auth_headers) { { "Authorization" => "Bearer #{api_key.raw_token}" } }

  def json_data
    response.parsed_body["data"]
  end

  def json_error
    response.parsed_body["error"]
  end

  describe "GET /api/v1/reconciliations" do
    context "with valid authentication" do
      let!(:older_reconciliation) { create(:reconciliation, user:) }
      let!(:newer_reconciliation) { create(:reconciliation, user:) }
      let!(:other_user_reconciliation) { create(:reconciliation) } # belongs to different user

      it "returns all reconciliations for current user" do
        get "/api/v1/reconciliations", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be true
        expect(json_data["reconciliations"].length).to eq(2)
      end

      it "does not return reconciliations from other users" do
        get "/api/v1/reconciliations", headers: auth_headers

        ids = json_data["reconciliations"].pluck("id")
        expect(ids).to include(older_reconciliation.id, newer_reconciliation.id)
        expect(ids).not_to include(other_user_reconciliation.id)
      end

      it "returns reconciliations ordered by most recent first" do
        get "/api/v1/reconciliations", headers: auth_headers

        expect(json_data["reconciliations"].first["id"]).to eq(newer_reconciliation.id)
      end

      it "includes pagination metadata" do
        get "/api/v1/reconciliations", headers: auth_headers

        expect(json_data["pagination"]).to include("count", "page", "limit", "last")
        expect(json_data["pagination"]["count"]).to eq(2)
        expect(json_data["pagination"]["page"]).to eq(1)
      end

      it "respects page parameter" do
        get "/api/v1/reconciliations", params: { page: 2 }, headers: auth_headers

        expect(json_data["reconciliations"]).to be_empty
        expect(json_data["pagination"]["page"]).to eq(2)
      end

      it "respects limit parameter" do
        get "/api/v1/reconciliations", params: { limit: 1 }, headers: auth_headers

        expect(json_data["reconciliations"].length).to eq(1)
        expect(json_data["pagination"]["limit"]).to eq(1)
        expect(json_data["pagination"]["last"]).to eq(2)
      end
    end

    context "without authentication" do
      it "returns 401 Unauthorized" do
        get "/api/v1/reconciliations"

        expect(response).to have_http_status(:unauthorized)
        expect(response.parsed_body["success"]).to be false
        expect(json_error["code"]).to eq("UNAUTHORIZED")
      end
    end

    context "with invalid token" do
      it "returns 401 Unauthorized" do
        get "/api/v1/reconciliations", headers: { "Authorization" => "Bearer invalid" }

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "GET /api/v1/reconciliations/:id" do
    let!(:reconciliation) { create(:reconciliation, :completed, user:) }

    context "with valid authentication" do
      it "returns the reconciliation" do
        get "/api/v1/reconciliations/#{reconciliation.id}", headers: auth_headers

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body["success"]).to be true
        expect(json_data["reconciliation"]["id"]).to eq(reconciliation.id)
        expect(json_data["reconciliation"]["status"]).to eq("completed")
      end

      it "returns all serialized fields" do
        get "/api/v1/reconciliations/#{reconciliation.id}", headers: auth_headers

        reconciliation_data = json_data["reconciliation"]
        expect(reconciliation_data).to include(
          "id", "status", "matched_count", "bank_only_count",
          "processor_only_count", "discrepancy_count", "error_message",
          "processed_at", "created_at", "updated_at"
        )
      end
    end

    context "when reconciliation belongs to another user" do
      let(:other_user) { create(:user) }
      let(:other_reconciliation) { create(:reconciliation, user: other_user) }

      it "returns 404 Not Found" do
        get "/api/v1/reconciliations/#{other_reconciliation.id}", headers: auth_headers

        expect(response).to have_http_status(:not_found)
        expect(response.parsed_body["success"]).to be false
        expect(json_error["code"]).to eq("NOT_FOUND")
      end
    end

    context "when reconciliation does not exist" do
      it "returns 404 Not Found" do
        get "/api/v1/reconciliations/non-existent-id", headers: auth_headers

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without authentication" do
      it "returns 401 Unauthorized" do
        get "/api/v1/reconciliations/#{reconciliation.id}"

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST /api/v1/reconciliations" do
    let(:valid_params) { { reconciliation: { status: "pending" } } }

    context "with valid authentication and params" do
      it "creates a new reconciliation" do
        expect do
          post "/api/v1/reconciliations", params: valid_params, headers: auth_headers
        end.to change(Reconciliation, :count).by(1)

        expect(response).to have_http_status(:created)
      end

      it "returns the created reconciliation" do
        post "/api/v1/reconciliations", params: valid_params, headers: auth_headers

        expect(response.parsed_body["success"]).to be true
        expect(json_data["reconciliation"]["status"]).to eq("pending")
        expect(json_data["reconciliation"]["id"]).to be_present
      end

      it "assigns the reconciliation to the current user" do
        post "/api/v1/reconciliations", params: valid_params, headers: auth_headers

        created = Reconciliation.find(json_data["reconciliation"]["id"])
        expect(created.user).to eq(user)
      end
    end

    context "with invalid params" do
      it "returns 422 with validation errors" do
        post "/api/v1/reconciliations", params: {}, headers: auth_headers

        expect(response).to have_http_status(:bad_request)
      end
    end

    context "without authentication" do
      it "returns 401 Unauthorized" do
        post "/api/v1/reconciliations", params: valid_params

        expect(response).to have_http_status(:unauthorized)
      end

      it "does not create a reconciliation" do
        expect do
          post "/api/v1/reconciliations", params: valid_params
        end.not_to change(Reconciliation, :count)
      end
    end

    context "with file uploads" do
      let(:bank_file) { fixture_file_upload("spec/fixtures/files/valid.csv", "text/csv") }
      let(:processor_file) { fixture_file_upload("spec/fixtures/files/processor_transactions.json", "application/json") }
      let(:invalid_file) { fixture_file_upload("spec/fixtures/files/invalid.pdf", "application/pdf") }

      it "creates reconciliation with attached files" do
        params = {
          reconciliation: {
            status: "pending",
            bank_file:,
            processor_file:
          }
        }

        expect do
          post "/api/v1/reconciliations", params:, headers: auth_headers
        end.to change(Reconciliation, :count).by(1)

        expect(response).to have_http_status(:created)
        expect(json_data["reconciliation"]["bank_file_attached"]).to be true
        expect(json_data["reconciliation"]["processor_file_attached"]).to be true
      end

      it "creates reconciliation with only bank_file" do
        params = { reconciliation: { status: "pending", bank_file: } }

        post "/api/v1/reconciliations", params:, headers: auth_headers

        expect(response).to have_http_status(:created)
        expect(json_data["reconciliation"]["bank_file_attached"]).to be true
        expect(json_data["reconciliation"]["processor_file_attached"]).to be false
      end

      it "rejects invalid file types" do
        params = { reconciliation: { status: "pending", bank_file: invalid_file } }

        post "/api/v1/reconciliations", params:, headers: auth_headers

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.parsed_body["success"]).to be false
        expect(json_error["code"]).to eq("VALIDATION_ERROR")
        expect(json_error["details"]["errors"]).to include("Bank file must be a CSV file")
      end
    end
  end
end
