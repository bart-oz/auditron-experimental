# frozen_string_literal: true

class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  # SQLite doesn't auto-generate UUIDs, so I generate them manually
  before_create :set_uuid_primary_key

  private

  def set_uuid_primary_key
    self.id ||= SecureRandom.uuid
  end
end
