require "rails_helper"

RSpec.describe AccountInvitation, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:account) }
    it { is_expected.to belong_to(:invited_by).class_name("User") }
  end

  describe "validations" do
    subject { create(:account_invitation) }

    it { is_expected.to validate_presence_of(:email) }
    it { is_expected.to validate_uniqueness_of(:token) }
    it { is_expected.to validate_uniqueness_of(:email).scoped_to(:account_id).with_message("has already been invited to this account") }

    it "validates email format" do
      invitation = build(:account_invitation, email: "invalid-email")
      expect(invitation).not_to be_valid
      expect(invitation.errors[:email]).to be_present
    end
  end

  describe "callbacks" do
    describe "generate_token" do
      it "generates a token before validation on create" do
        invitation = build(:account_invitation, token: nil)
        invitation.valid?
        expect(invitation.token).to be_present
      end

      it "does not overwrite an existing token" do
        invitation = build(:account_invitation, token: "custom-token")
        invitation.valid?
        expect(invitation.token).to eq("custom-token")
      end
    end

    describe "set_expiration" do
      it "sets expiration to 7 days from now on create" do
        invitation = build(:account_invitation, expires_at: nil)
        invitation.valid?
        expect(invitation.expires_at).to be_within(1.minute).of(7.days.from_now)
      end
    end
  end

  describe "scopes" do
    let!(:pending_invitation) { create(:account_invitation) }
    let!(:expired_invitation) { create(:account_invitation, :expired) }
    let!(:accepted_invitation) { create(:account_invitation, :accepted) }

    describe ".pending" do
      it "returns only pending invitations" do
        expect(described_class.pending).to contain_exactly(pending_invitation)
      end
    end

    describe ".expired" do
      it "returns only expired invitations" do
        expect(described_class.expired).to contain_exactly(expired_invitation)
      end
    end

    describe ".accepted" do
      it "returns only accepted invitations" do
        expect(described_class.accepted).to contain_exactly(accepted_invitation)
      end
    end
  end

  describe "#pending?" do
    it "returns true for pending invitations" do
      invitation = create(:account_invitation)
      expect(invitation.pending?).to be true
    end

    it "returns false for expired invitations" do
      invitation = create(:account_invitation, :expired)
      expect(invitation.pending?).to be false
    end

    it "returns false for accepted invitations" do
      invitation = create(:account_invitation, :accepted)
      expect(invitation.pending?).to be false
    end
  end

  describe "#expired?" do
    it "returns false for pending invitations" do
      invitation = create(:account_invitation)
      expect(invitation.expired?).to be false
    end

    it "returns true for expired invitations" do
      invitation = create(:account_invitation, :expired)
      expect(invitation.expired?).to be true
    end
  end

  describe "#accepted?" do
    it "returns false for pending invitations" do
      invitation = create(:account_invitation)
      expect(invitation.accepted?).to be false
    end

    it "returns true for accepted invitations" do
      invitation = create(:account_invitation, :accepted)
      expect(invitation.accepted?).to be true
    end
  end

  describe "#accept!" do
    let(:invitation) { create(:account_invitation) }
    let(:user) { create(:user) }

    context "when invitation is pending" do
      it "returns true" do
        expect(invitation.accept!(user)).to be true
      end

      it "sets accepted_at" do
        invitation.accept!(user)
        expect(invitation.reload.accepted_at).to be_within(1.second).of(Time.current)
      end

      it "creates a membership for the user" do
        expect { invitation.accept!(user) }.to change { invitation.account.memberships.count }.by(1)
      end

      it "creates a member-level membership" do
        invitation.accept!(user)
        membership = invitation.account.memberships.find_by(user: user)
        expect(membership.role).to eq("member")
      end
    end

    context "when invitation is expired" do
      let(:invitation) { create(:account_invitation, :expired) }

      it "returns false" do
        expect(invitation.accept!(user)).to be false
      end

      it "does not create a membership for invited user" do
        initial_count = Membership.count
        invitation.accept!(user)
        # Count should only increase by 2 (the 2 users created have default accounts)
        # not by 3 (which would happen if the expired invitation created a membership)
        expect(Membership.where(account: invitation.account, user: user).count).to eq(0)
      end
    end

    context "when invitation is already accepted" do
      let(:invitation) { create(:account_invitation, :accepted) }

      it "returns false" do
        expect(invitation.accept!(user)).to be false
      end
    end
  end
end
