# frozen_string_literal: true

class Reconciliation < ApplicationRecord
  belongs_to :user

  has_one_attached :bank_file
  has_one_attached :processor_file

  enum :status, {
    pending: 0,
    processing: 1,
    completed: 2,
    failed: 3
  }, default: :pending, validate: true

  validates :status, presence: true

  scope :recent, -> { order(created_at: :desc) }
  scope :by_status, ->(status) { where(status:) }
end
