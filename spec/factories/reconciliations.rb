# frozen_string_literal: true

FactoryBot.define do
  factory :reconciliation do
    user
    status { :pending }

    trait :processing do
      status { :processing }
    end

    trait :completed do
      status { :completed }
      matched_count { 100 }
      bank_only_count { 5 }
      processor_only_count { 3 }
      discrepancy_count { 2 }
      processed_at { Time.current }
      report do
        <<~MARKDOWN
          # Reconciliation Report

          Generated: #{Time.current.strftime('%Y-%m-%d %H:%M:%S UTC')}

          ## Summary

          | Metric | Count |
          |--------|-------|
          | ✅ Matched Transactions | 100 |
          | ⚠️ Discrepancies | 2 |
          | 🏦 Bank-only | 5 |
          | 💳 Processor-only | 3 |
        MARKDOWN
      end
    end

    trait :failed do
      status { :failed }
      error_message { "File parsing error" }
    end
  end
end
