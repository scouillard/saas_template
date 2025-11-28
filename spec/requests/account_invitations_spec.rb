require "rails_helper"

RSpec.describe "Account Invitations", type: :request do
  describe "POST /invitations" do
    let(:user) { create(:user) }

    before { sign_in user }

    it "creates an invitation and sends an email" do
      expect {
        post invitations_path, params: { email: "invitee@example.com" }
      }.to change(AccountInvitation, :count).by(1)
        .and have_enqueued_mail(AccountInvitationMailer, :invite_email)

      expect(response).to redirect_to(team_path)
    end

    it "rejects duplicate pending invitations" do
      create(:account_invitation, account: user.accounts.first, email: "invitee@example.com")

      expect {
        post invitations_path, params: { email: "invitee@example.com" }
      }.not_to change(AccountInvitation, :count)

      expect(response).to redirect_to(team_path)
      expect(flash[:alert]).to include("already been sent")
    end
  end

  describe "GET /invitations/:token" do
    let(:invitation) { create(:account_invitation) }

    it "redirects to signup with invitation token for unauthenticated users" do
      get accept_invitation_path(token: invitation.token)
      expect(response).to redirect_to(new_user_registration_path(invitation_token: invitation.token))
    end

    context "when user is signed in with matching email" do
      let(:user) { create(:user, email: invitation.email) }

      before { sign_in user }

      it "accepts the invitation and adds user to account" do
        get accept_invitation_path(token: invitation.token)
        expect(response).to redirect_to(root_path)
        expect(invitation.reload.accepted_at).to be_present
        expect(user.accounts).to include(invitation.account)
      end
    end

    context "when invitation is expired" do
      let(:expired_invitation) { create(:account_invitation, expires_at: 1.day.ago) }

      it "shows expired error" do
        get accept_invitation_path(token: expired_invitation.token)
        expect(response).to redirect_to(root_path)
        expect(flash[:alert]).to include("expired")
      end
    end
  end
end
