# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApiKey, type: :model do
  describe "associations" do
    it "belongs to user" do
      expect(described_class.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe "validations" do
    subject { build(:api_key) }

    it { is_expected.to validate_presence_of(:name) }
  end

  describe "token generation" do
    it "generates token_digest on create" do
      api_key = build(:api_key)
      expect(api_key.token_digest).to be_nil

      api_key.save!
      expect(api_key.token_digest).to be_present
    end

    it "exposes raw_token after creation" do
      api_key = create(:api_key)
      expect(api_key.raw_token).to be_present
      expect(api_key.raw_token.length).to eq(40) # hex(20) = 40 chars
    end

    it "does not persist raw_token" do
      api_key = create(:api_key)
      reloaded = described_class.find(api_key.id)
      expect(reloaded.raw_token).to be_nil
    end
  end

  describe ".authenticate" do
    it "returns api_key when token matches" do
      api_key = create(:api_key)
      raw_token = api_key.raw_token

      expect(described_class.authenticate(raw_token)).to eq(api_key)
    end

    it "returns nil for invalid token" do
      expect(described_class.authenticate("invalid_token")).to be_nil
    end

    it "returns nil for blank token" do
      expect(described_class.authenticate("")).to be_nil
      expect(described_class.authenticate(nil)).to be_nil
    end
  end

  describe ".digest" do
    it "returns SHA256 hex digest" do
      result = described_class.digest("test_token")
      expect(result).to eq(Digest::SHA256.hexdigest("test_token"))
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      api_key = build(:api_key, :expired)
      expect(api_key).to be_expired
    end

    it "returns false when expires_at is in the future" do
      api_key = build(:api_key, expires_at: 1.day.from_now)
      expect(api_key).not_to be_expired
    end

    it "returns false when expires_at is nil" do
      api_key = build(:api_key, :never_expires)
      expect(api_key).not_to be_expired
    end
  end

  describe "#touch_last_used" do
    it "updates last_used_at to current time" do
      api_key = create(:api_key)
      expect(api_key.last_used_at).to be_nil

      freeze_time do
        api_key.touch_last_used
        expect(api_key.last_used_at).to eq(Time.current)
      end
    end

    it "persists the update" do
      api_key = create(:api_key)
      freeze_time do
        api_key.touch_last_used
        reloaded = described_class.find(api_key.id)
        expect(reloaded.last_used_at).to eq(Time.current)
      end
    end
  end

  describe "factory" do
    it "creates a valid api_key" do
      expect(build(:api_key)).to be_valid
    end

    it "creates a valid and persisted api_key" do
      api_key = create(:api_key)
      expect(api_key).to be_persisted
      expect(api_key.raw_token).to be_present
      expect(api_key.token_digest).to be_present
    end

    it "creates expired api_key with trait" do
      api_key = build(:api_key, :expired)
      expect(api_key.expires_at).to be < Time.current
    end

    it "creates never-expiring api_key with trait" do
      api_key = build(:api_key, :never_expires)
      expect(api_key.expires_at).to be_nil
    end
  end
end
