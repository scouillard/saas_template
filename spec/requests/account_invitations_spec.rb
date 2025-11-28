require "rails_helper"

RSpec.describe "AccountInvitations", type: :request do
  describe "POST /invitations" do
    let(:user) { create(:user) }
    let(:account) { user.accounts.first }

    before do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }
    end

    it "creates an invitation and sends email" do
      expect {
        post invitations_path, params: { email: "invitee@example.com" }
      }.to change(AccountInvitation, :count).by(1)
        .and have_enqueued_mail(AccountInvitationMailer, :invite)

      expect(response).to redirect_to(team_path)
      expect(flash[:notice]).to include("Invitation sent")
    end

    it "redirects with alert on duplicate email" do
      create(:account_invitation, account: account, email: "existing@example.com")

      post invitations_path, params: { email: "existing@example.com" }

      expect(response).to redirect_to(team_path)
      expect(flash[:alert]).to include("already been invited")
    end
  end

  describe "POST /invitations when not signed in" do
    it "redirects to sign in" do
      post invitations_path, params: { email: "invitee@example.com" }
      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "GET /invitations/:token/accept" do
    let(:inviter) { create(:user) }
    let(:account) { inviter.accounts.first }
    let(:invitation) { create(:account_invitation, account: account, invited_by: inviter) }

    context "when signed in" do
      let(:user) { create(:user) }

      before do
        post user_session_path, params: { user: { email: user.email, password: "password123" } }
      end

      it "accepts invitation and adds user to account" do
        expect {
          get accept_invitation_path(token: invitation.token)
        }.to change { account.memberships.count }.by(1)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("joined")
        expect(invitation.reload.accepted?).to be true
      end

      it "redirects if already a member" do
        account.memberships.create!(user: user, role: :member)

        get accept_invitation_path(token: invitation.token)

        expect(response).to redirect_to(root_path)
        expect(flash[:notice]).to include("already a member")
      end
    end

    context "when not signed in" do
      it "stores token in session and redirects to signup" do
        get accept_invitation_path(token: invitation.token)

        expect(response).to redirect_to(new_user_registration_path)
        expect(session[:invitation_token]).to eq(invitation.token)
      end
    end

    context "with invalid token" do
      it "redirects with alert" do
        get accept_invitation_path(token: "invalid")

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("Invalid")
      end
    end

    context "with expired invitation" do
      let(:invitation) { create(:account_invitation, :expired, account: account, invited_by: inviter) }

      it "redirects with alert" do
        get accept_invitation_path(token: invitation.token)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("expired")
      end
    end

    context "with already accepted invitation" do
      let(:invitation) { create(:account_invitation, :accepted, account: account, invited_by: inviter) }

      it "redirects with alert" do
        get accept_invitation_path(token: invitation.token)

        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("already been accepted")
      end
    end
  end
end
