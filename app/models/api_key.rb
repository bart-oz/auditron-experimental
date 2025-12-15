# frozen_string_literal: true

class ApiKey < ApplicationRecord
  belongs_to :user

  validates :token_digest, presence: true, uniqueness: true
  validates :name, presence: true

  before_validation :generate_token, on: :create

  attr_reader :raw_token

  def self.authenticate(token)
    return nil if token.blank?

    find_by(token_digest: digest(token))
  end

  def self.digest(token)
    Digest::SHA256.hexdigest(token)
  end

  def expired?
    expires_at? && expires_at < Time.current
  end

  def touch_last_used
    update!(last_used_at: Time.current)
  end

  private

  def generate_token
    @raw_token = SecureRandom.hex(20)
    self.token_digest = Digest::SHA256.hexdigest(@raw_token)
  end
end
