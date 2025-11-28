require "rails_helper"

# rubocop:disable RSpec/SpecFilePathFormat
RSpec.describe Devise::Mailer, type: :mailer do
  describe "confirmation_instructions" do
    let(:user) { create(:user, confirmed_at: nil) }
    let(:token) { "test-confirmation-token" }
    let(:mail) { described_class.confirmation_instructions(user, token) }

    context "happy path" do
      it "renders the headers" do
        expect(mail.subject).to eq("Confirmation instructions")
        expect(mail.to).to eq([ user.email ])
      end

      it "renders the body with confirmation link" do
        expect(mail.body.encoded).to include("Confirm my account")
        expect(mail.body.encoded).to include(token)
      end

      it "includes welcome message and email" do
        expect(mail.body.encoded).to include("Welcome")
        expect(mail.body.encoded).to include(user.email)
      end

      it "has both html and text parts" do
        expect(mail.html_part).to be_present
        expect(mail.text_part).to be_present
      end

      it "includes the app name in the html layout" do
        expect(mail.html_part.body.encoded).to include(Rails.application.class.module_parent_name)
      end
    end

    context "unhappy path" do
      it "does not include sensitive information" do
        expect(mail.body.encoded).not_to include(user.encrypted_password)
      end

      it "includes fallback message for non-users" do
        expect(mail.body.encoded).to include("If you didn't create an account")
      end
    end
  end
end
# rubocop:enable RSpec/SpecFilePathFormat
