require "rails_helper"
require "ostruct"

RSpec.describe User, type: :model do
  describe ".find_or_create_from_oauth" do
    let(:auth) do
      OpenStruct.new(
        provider: "google_oauth2",
        uid: "123456789",
        info: OpenStruct.new(email: "oauth@example.com", name: "OAuth User")
      )
    end

    context "when user exists with same provider and uid" do
      let!(:existing_user) { create(:user, :oauth, provider: "google_oauth2", uid: "123456789", email: "oauth@example.com") }

      it "returns the existing user" do
        user = described_class.find_or_create_from_oauth(auth)
        expect(user).to eq(existing_user)
      end
    end

    context "when user exists with same email but no OAuth" do
      let!(:existing_user) { create(:user, email: "oauth@example.com", provider: nil, uid: nil) }

      it "links OAuth credentials to existing user" do
        user = described_class.find_or_create_from_oauth(auth)

        expect(user).to eq(existing_user)
        expect(user.provider).to eq("google_oauth2")
        expect(user.uid).to eq("123456789")
      end
    end

    context "when no user exists with email or OAuth credentials" do
      it "creates a new user" do
        expect { described_class.find_or_create_from_oauth(auth) }.to change(described_class, :count).by(1)
      end

      it "sets the correct attributes" do
        user = described_class.find_or_create_from_oauth(auth)

        expect(user.email).to eq("oauth@example.com")
        expect(user.name).to eq("OAuth User")
        expect(user.provider).to eq("google_oauth2")
        expect(user.uid).to eq("123456789")
        expect(user.confirmed_at).to be_present
      end
    end

    context "with case-insensitive email matching" do
      let!(:existing_user) { create(:user, email: "OAuth@Example.com") }

      let(:auth) do
        OpenStruct.new(
          provider: "google_oauth2",
          uid: "123456789",
          info: OpenStruct.new(email: "oauth@example.com", name: "OAuth User")
        )
      end

      it "finds existing user regardless of email case" do
        user = described_class.find_or_create_from_oauth(auth)
        expect(user).to eq(existing_user)
      end
    end
  end

  describe "callbacks" do
    describe "create_default_account" do
      it "creates a default account with user as owner" do
        user = create(:user, name: "Test User")

        expect(user.accounts.count).to eq(1)
        expect(user.accounts.first.name).to eq("Test User's Team")
        expect(user.memberships.first.role).to eq("owner")
      end

      it "uses email prefix for team name when name is blank" do
        user = create(:user, name: nil, email: "john@example.com")

        expect(user.accounts.first.name).to eq("John's Team")
      end
    end

    describe "when joining via invitation" do
      let(:inviter) { create(:user) }
      let(:account) { inviter.accounts.first }
      let(:invitation) { create(:account_invitation, account: account, invited_by: inviter, email: "invitee@example.com") }

      it "does not create default account when invitation_token is present" do
        user = described_class.create!(
          email: "invitee@example.com",
          password: "password123",
          confirmed_at: Time.current,
          invitation_token: invitation.token
        )

        expect(user.accounts).to eq([ account ])
        expect(user.memberships.first.role).to eq("member")
      end

      it "accepts the pending invitation" do
        user = described_class.create!(
          email: "invitee@example.com",
          password: "password123",
          confirmed_at: Time.current,
          invitation_token: invitation.token
        )

        expect(invitation.reload.accepted?).to be true
      end
    end
  end

  describe "#joining_via_invitation?" do
    it "returns true when invitation_token is present" do
      user = described_class.new(invitation_token: "some_token")
      expect(user.joining_via_invitation?).to be true
    end

    it "returns false when invitation_token is blank" do
      user = described_class.new
      expect(user.joining_via_invitation?).to be false
    end
  end
end
