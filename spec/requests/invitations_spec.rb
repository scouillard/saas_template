require "rails_helper"

RSpec.describe "Invitations", type: :request do
  let(:user) { create(:user) }
  let(:account) { user.accounts.first }

  before { sign_in user }

  describe "POST /invitations" do
    context "with valid email" do
      it "creates an invitation" do
        expect {
          post invitations_path, params: { email: "newmember@example.com" }
        }.to change(AccountInvitation, :count).by(1)
      end

      it "sends an invitation email" do
        expect {
          post invitations_path, params: { email: "newmember@example.com" }
        }.to have_enqueued_mail(AccountInvitationMailer, :invite)
      end

      it "redirects to team page with success notice" do
        post invitations_path, params: { email: "newmember@example.com" }
        expect(response).to redirect_to(team_path)
        follow_redirect!
        expect(response.body).to include("Invitation sent to newmember@example.com")
      end
    end

    context "with invalid email" do
      it "does not create an invitation" do
        expect {
          post invitations_path, params: { email: "invalid-email" }
        }.not_to change(AccountInvitation, :count)
      end

      it "redirects to team page with error alert" do
        post invitations_path, params: { email: "invalid-email" }
        expect(response).to redirect_to(team_path)
      end
    end

    context "when email already invited" do
      before { create(:account_invitation, account: account, invited_by: user, email: "existing@example.com") }

      it "does not create a duplicate invitation" do
        expect {
          post invitations_path, params: { email: "existing@example.com" }
        }.not_to change(AccountInvitation, :count)
      end
    end
  end

  describe "DELETE /invitations/:id" do
    let!(:invitation) { create(:account_invitation, account: account, invited_by: user) }

    it "destroys the invitation" do
      expect {
        delete invitation_path(invitation)
      }.to change(AccountInvitation, :count).by(-1)
    end

    it "redirects to team page" do
      delete invitation_path(invitation)
      expect(response).to redirect_to(team_path)
    end
  end
end
