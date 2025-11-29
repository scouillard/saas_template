require "rails_helper"

RSpec.describe ContactMessage, type: :model do
  describe "validations" do
    it "is valid with all required attributes" do
      contact_message = described_class.new(
        name: "John Doe",
        email: "john@example.com",
        title: "Question about pricing",
        message: "I have a question about your pricing plans."
      )
      expect(contact_message).to be_valid
    end

    it "is invalid without a name" do
      contact_message = described_class.new(name: nil)
      expect(contact_message).not_to be_valid
      expect(contact_message.errors[:name]).to include("can't be blank")
    end

    it "is invalid without an email" do
      contact_message = described_class.new(email: nil)
      expect(contact_message).not_to be_valid
      expect(contact_message.errors[:email]).to include("can't be blank")
    end

    it "is invalid with an improperly formatted email" do
      contact_message = described_class.new(email: "invalid-email")
      expect(contact_message).not_to be_valid
      expect(contact_message.errors[:email]).to include("is invalid")
    end

    it "is invalid without a title" do
      contact_message = described_class.new(title: nil)
      expect(contact_message).not_to be_valid
      expect(contact_message.errors[:title]).to include("can't be blank")
    end

    it "is invalid without a message" do
      contact_message = described_class.new(message: nil)
      expect(contact_message).not_to be_valid
      expect(contact_message.errors[:message]).to include("can't be blank")
    end
  end
end
