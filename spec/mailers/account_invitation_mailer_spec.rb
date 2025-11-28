require "rails_helper"

RSpec.describe AccountInvitationMailer, type: :mailer do
  describe "#invite_email" do
    let(:invitation) { create(:account_invitation) }
    let(:mail) { described_class.invite_email(invitation) }

    it "sends to the invited email address" do
      expect(mail.to).to eq([ invitation.email ])
    end

    it "includes the account name in the subject" do
      expect(mail.subject).to include(invitation.account.name)
    end

    it "includes the invitation link in the body" do
      expect(mail.body.encoded).to include(invitation.token)
    end
  end
end
