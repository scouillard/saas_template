require "rails_helper"

RSpec.describe BillingMailer, type: :mailer do
  let(:account) { create(:account, :with_stripe) }
  let(:user) { create(:user) }
  let!(:membership) { create(:membership, user: user, account: account, role: "owner") }

  describe "#payment_failed" do
    let(:event) { PaymentFailedNotifier.with(account: account) }
    let(:notification) { Noticed::Notification.new(event: event, recipient: user) }

    before do
      event.save!
      notification.event = event
    end

    it "renders the subject" do
      mail = described_class.payment_failed(user, notification)

      expect(mail.subject).to eq("Action required: Payment failed")
    end

    it "renders the receiver email" do
      mail = described_class.payment_failed(user, notification)

      expect(mail.to).to eq([ user.email ])
    end

    it "renders the update payment link" do
      mail = described_class.payment_failed(user, notification)

      expect(mail.body.encoded).to include("Update Payment Method")
    end
  end

  describe "#subscription_canceled" do
    let(:event) { SubscriptionCanceledNotifier.with(account: account) }
    let(:notification) { Noticed::Notification.new(event: event, recipient: user) }

    before do
      event.save!
      notification.event = event
    end

    it "renders the subject" do
      mail = described_class.subscription_canceled(user, notification)

      expect(mail.subject).to eq("Your subscription has been canceled")
    end

    it "renders the receiver email" do
      mail = described_class.subscription_canceled(user, notification)

      expect(mail.to).to eq([ user.email ])
    end

    it "renders the view plans link" do
      mail = described_class.subscription_canceled(user, notification)

      expect(mail.body.encoded).to include("View Plans")
    end
  end
end
