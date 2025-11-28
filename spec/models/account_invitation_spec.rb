require "rails_helper"

RSpec.describe AccountInvitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:inviter).class_name("User") }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:email) }
  end

  describe "token generation" do
    it "generates a unique token before validation" do
      invitation = build(:account_invitation, token: nil)
      invitation.valid?
      expect(invitation.token).to be_present
    end
  end

  describe "#pending?" do
    it "returns true when not accepted and not expired" do
      invitation = build(:account_invitation, accepted_at: nil, expires_at: 1.day.from_now)
      expect(invitation.pending?).to be true
    end
  end

  describe "#accepted?" do
    it "returns true when accepted_at is present" do
      invitation = build(:account_invitation, accepted_at: Time.current)
      expect(invitation.accepted?).to be true
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      invitation = build(:account_invitation, expires_at: 1.day.ago)
      expect(invitation.expired?).to be true
    end
  end
end
