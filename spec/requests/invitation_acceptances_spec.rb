require "rails_helper"

RSpec.describe "InvitationAcceptances", type: :request do
  let(:inviter) { create(:user) }
  let(:account) { inviter.accounts.first }

  describe "GET /invitations/:token" do
    context "with valid pending invitation" do
      let(:invitation) { create(:account_invitation, account: account, invited_by: inviter, email: "invitee@example.com") }

      it "returns success" do
        get accept_invitation_path(token: invitation.token)
        expect(response).to have_http_status(:ok)
      end

      it "stores invitation token in session" do
        get accept_invitation_path(token: invitation.token)
        expect(session[:invitation_token]).to eq(invitation.token)
      end

      context "when user is signed in with matching email" do
        let(:invitee) { create(:user, email: "invitee@example.com") }

        before { sign_in invitee }

        it "shows accept button" do
          get accept_invitation_path(token: invitation.token)
          expect(response.body).to include("Accept Invitation")
        end
      end

      context "when user is signed in with different email" do
        let(:other_user) { create(:user, email: "other@example.com") }

        before { sign_in other_user }

        it "redirects with error" do
          get accept_invitation_path(token: invitation.token)
          expect(response).to redirect_to(root_path)
          follow_redirect!
          expect(response.body).to include("different email address")
        end
      end
    end

    context "with expired invitation" do
      let(:invitation) { create(:account_invitation, :expired, account: account, invited_by: inviter) }

      it "redirects with error" do
        get accept_invitation_path(token: invitation.token)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with accepted invitation" do
      let(:invitation) { create(:account_invitation, :accepted, account: account, invited_by: inviter) }

      it "redirects with notice" do
        get accept_invitation_path(token: invitation.token)
        expect(response).to redirect_to(root_path)
      end
    end

    context "with invalid token" do
      it "redirects with error" do
        get accept_invitation_path(token: "invalid-token")
        expect(response).to redirect_to(root_path)
      end
    end
  end

  describe "POST /invitations/:token/accept" do
    let(:invitation) { create(:account_invitation, account: account, invited_by: inviter, email: "invitee@example.com") }

    context "when user is signed in with matching email" do
      let(:invitee) { create(:user, email: "invitee@example.com") }

      before { sign_in invitee }

      it "accepts the invitation" do
        post confirm_invitation_path(token: invitation.token)
        expect(invitation.reload.accepted?).to be true
      end

      it "adds user to account" do
        expect {
          post confirm_invitation_path(token: invitation.token)
        }.to change { account.memberships.count }.by(1)
      end

      it "redirects to root with success message" do
        post confirm_invitation_path(token: invitation.token)
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("You have joined")
      end
    end

    context "when user is not signed in" do
      it "redirects to registration page" do
        post confirm_invitation_path(token: invitation.token)
        expect(response).to redirect_to(new_user_registration_path)
      end
    end

    context "with expired invitation" do
      let(:invitation) { create(:account_invitation, :expired, account: account, invited_by: inviter) }

      it "redirects with error" do
        post confirm_invitation_path(token: invitation.token)
        expect(response).to redirect_to(root_path)
      end
    end
  end
end
