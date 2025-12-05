require "rails_helper"

RSpec.describe Subscriber, type: :model do
  describe "validations" do
    it "is valid with a valid email" do
      subscriber = described_class.new(email: "test@example.com")
      expect(subscriber).to be_valid
    end

    it "is invalid without an email" do
      subscriber = described_class.new(email: nil)
      expect(subscriber).not_to be_valid
      expect(subscriber.errors[:email]).to include("can't be blank")
    end

    it "is invalid with an improperly formatted email" do
      subscriber = described_class.new(email: "invalid-email")
      expect(subscriber).not_to be_valid
      expect(subscriber.errors[:email]).to include("is invalid")
    end

    it "is invalid with a duplicate email (case insensitive)" do
      described_class.create!(email: "test@example.com")
      subscriber = described_class.new(email: "TEST@example.com")
      expect(subscriber).not_to be_valid
      expect(subscriber.errors[:email]).to include("is already subscribed")
    end
  end

  describe "callbacks" do
    it "downcases email before saving" do
      subscriber = described_class.create!(email: "TEST@EXAMPLE.COM")
      expect(subscriber.email).to eq("test@example.com")
    end
  end
end
