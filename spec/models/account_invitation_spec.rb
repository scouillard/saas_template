require "rails_helper"

RSpec.describe AccountInvitation, type: :model do
  describe "validations" do
    subject { build(:account_invitation) }

    it { is_expected.to be_valid }

    it "requires an email" do
      subject.email = nil
      expect(subject).not_to be_valid
    end

    it "requires a valid email format" do
      subject.email = "invalid"
      expect(subject).not_to be_valid
    end

    it "requires a unique email per account" do
      existing = create(:account_invitation)
      subject.account = existing.account
      subject.email = existing.email

      expect(subject).not_to be_valid
      expect(subject.errors[:email]).to include("has already been invited to this account")
    end
  end

  describe "callbacks" do
    it "generates a token before create" do
      invitation = build(:account_invitation, token: nil)
      invitation.save!

      expect(invitation.token).to be_present
      expect(invitation.token.length).to be >= 32
    end

    it "sets expiration to 7 days from now" do
      invitation = create(:account_invitation)

      expect(invitation.expires_at).to be_within(1.second).of(7.days.from_now)
    end
  end

  describe "#pending?" do
    it "returns true when not accepted and not expired" do
      invitation = build(:account_invitation)
      expect(invitation.pending?).to be true
    end

    it "returns false when accepted" do
      invitation = build(:account_invitation, :accepted)
      expect(invitation.pending?).to be false
    end

    it "returns false when expired" do
      invitation = build(:account_invitation, :expired)
      expect(invitation.pending?).to be false
    end
  end

  describe "#accepted?" do
    it "returns true when accepted_at is present" do
      invitation = build(:account_invitation, :accepted)
      expect(invitation.accepted?).to be true
    end

    it "returns false when accepted_at is nil" do
      invitation = build(:account_invitation)
      expect(invitation.accepted?).to be false
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      invitation = build(:account_invitation, :expired)
      expect(invitation.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      invitation = build(:account_invitation)
      expect(invitation.expired?).to be false
    end
  end

  describe "#accept!" do
    let(:invitation) { create(:account_invitation) }
    let(:user) { create(:user) }

    it "creates a membership for the user" do
      expect { invitation.accept!(user) }.to change { invitation.account.memberships.count }.by(1)
    end

    it "sets the user as a member role" do
      membership = invitation.accept!(user)
      expect(membership.role).to eq("member")
    end

    it "sets accepted_at timestamp" do
      invitation.accept!(user)
      expect(invitation.reload.accepted_at).to be_present
    end

    it "returns the membership" do
      result = invitation.accept!(user)
      expect(result).to be_a(Membership)
      expect(result.user).to eq(user)
    end

    it "raises error if already accepted" do
      invitation.update!(accepted_at: Time.current)
      expect { invitation.accept!(user) }.to raise_error("Invitation has already been accepted")
    end

    it "raises error if expired" do
      invitation.update!(expires_at: 1.day.ago)
      expect { invitation.accept!(user) }.to raise_error("Invitation has expired")
    end
  end
end
