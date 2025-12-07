require "rails_helper"
require "ostruct"

RSpec.describe Stripe::InvoicePaymentFailedHandler do
  let(:account) { create(:account, :with_stripe, subscription_status: "active") }
  let(:owner) { create(:user) }
  let!(:membership) { create(:membership, user: owner, account: account, role: "owner") }

  let(:invoice) { OpenStruct.new(id: "inv_123", customer: account.stripe_customer_id) }
  let(:event) { OpenStruct.new(type: "invoice.payment_failed", data: OpenStruct.new(object: invoice)) }

  describe ".call" do
    it "updates subscription_status to past_due" do
      described_class.call(event)

      expect(account.reload.subscription_status).to eq("past_due")
    end

    it "sends notification to account owner" do
      expect {
        described_class.call(event)
      }.to change(Noticed::Event, :count).by(1)
    end

    it "logs the failure event" do
      allow(Rails.logger).to receive(:info)

      described_class.call(event)

      expect(Rails.logger).to have_received(:info).with(/Payment failed for account #{account.id}/)
    end

    context "when account is already past_due" do
      before { account.update!(subscription_status: "past_due") }

      it "does not update subscription status again" do
        expect(account).not_to receive(:update!)

        described_class.call(event)
      end

      it "does not send duplicate notification" do
        expect {
          described_class.call(event)
        }.not_to change(Noticed::Event, :count)
      end
    end

    context "when account is not found" do
      let(:invoice) { ::OpenStruct.new(id: "inv_123", customer: "cus_unknown") }

      it "returns false" do
        result = described_class.call(event)

        expect(result).to be false
      end
    end
  end
end
