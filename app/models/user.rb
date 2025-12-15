# frozen_string_literal: true

class User < ApplicationRecord
  has_secure_password

  has_many :api_keys, dependent: :destroy
  has_many :reconciliations, dependent: :destroy

  validates :email, presence: true,
                    uniqueness: { case_sensitive: false },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  normalizes :email, with: ->(email) { email.strip.downcase }
end
