# frozen_string_literal: true

FactoryBot.define do
  factory :api_key do
    user
    sequence(:name) { |n| "API Key #{n}" }
    expires_at { 30.days.from_now }

    trait :expired do
      expires_at { 1.day.ago }
    end

    trait :never_expires do
      expires_at { nil }
    end
  end
end
