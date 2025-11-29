require "rails_helper"

RSpec.describe AccountInvitationMailer, type: :mailer do
  describe "#invite" do
    let(:inviter) { create(:user, name: "John Doe") }
    let(:account) { inviter.accounts.first }
    let(:invitation) { create(:account_invitation, account: account, invited_by: inviter, email: "invitee@example.com") }
    let(:mail) { described_class.invite(invitation) }

    it "renders the subject" do
      expect(mail.subject).to eq("You've been invited to join #{account.name}")
    end

    it "sends to invitation email" do
      expect(mail.to).to eq([ "invitee@example.com" ])
    end

    it "includes accept link in body" do
      expect(mail.body.encoded).to include(accept_invitation_url(token: invitation.token))
    end

    it "includes inviter name in body" do
      expect(mail.body.encoded).to include("John Doe")
    end

    it "includes account name in body" do
      expect(mail.body.encoded).to include(account.name)
    end
  end
end
