require "rails_helper"

RSpec.describe AccountInvitationMailer, type: :mailer do
  describe "#invite" do
    let(:inviter) { create(:user, name: "John Doe") }
    let(:account) { inviter.accounts.first }
    let(:invitation) { create(:account_invitation, account: account, invited_by: inviter, email: "invitee@example.com") }
    let(:mail) { described_class.invite(invitation) }

    it "sends to the invitee email" do
      expect(mail.to).to eq([ "invitee@example.com" ])
    end

    it "includes inviter name in subject" do
      expect(mail.subject).to include("John Doe")
    end

    it "includes account name in subject" do
      expect(mail.subject).to include(account.name)
    end

    it "includes accept link in body" do
      expect(mail.body.encoded).to include(accept_invitation_url(token: invitation.token))
    end

    it "includes inviter info in body" do
      expect(mail.body.encoded).to include("John Doe")
    end

    context "when inviter has no name" do
      let(:inviter) { create(:user, name: nil, email: "inviter@example.com") }

      it "uses email in subject" do
        expect(mail.subject).to include("inviter@example.com")
      end
    end
  end
end
