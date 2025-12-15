# frozen_string_literal: true

require "rails_helper"

RSpec.describe User, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:api_keys).dependent(:destroy) }
    it { is_expected.to have_many(:reconciliations).dependent(:destroy) }
  end

  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:email).case_insensitive }
    it { is_expected.to have_secure_password }

    it "validates email format" do
      user = build(:user, email: "invalid")
      expect(user).not_to be_valid
      expect(user.errors[:email]).to include("is invalid")
    end

    it "accepts valid email" do
      user = build(:user, email: "valid@example.com")
      expect(user).to be_valid
    end
  end

  describe "normalizations" do
    it "normalizes email to lowercase and strips whitespace" do
      user = create(:user, email: "  TEST@EXAMPLE.COM  ")
      expect(user.email).to eq("test@example.com")
    end
  end

  describe "has_secure_password" do
    it "creates password_digest when password is set" do
      user = create(:user, password: "secret123", password_confirmation: "secret123")
      expect(user.password_digest).to be_present
      expect(user.password_digest).not_to eq("secret123")
    end

    it "authenticates with correct password" do
      user = create(:user, password: "correct_password", password_confirmation: "correct_password")
      expect(user.authenticate("correct_password")).to eq(user)
      expect(user.authenticate("wrong_password")).to be(false)
    end
  end

  describe "factory" do
    it "creates a valid user" do
      expect(build(:user)).to be_valid
    end

    it "persists user to database" do
      user = create(:user)
      expect(described_class.find(user.id)).to eq(user)
    end
  end
end
