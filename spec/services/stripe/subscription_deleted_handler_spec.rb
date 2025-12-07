require "rails_helper"
require "ostruct"

RSpec.describe Stripe::SubscriptionDeletedHandler do
  let(:account) { create(:account, :with_stripe, subscription_status: "past_due") }
  let(:owner) { create(:user) }
  let!(:membership) { create(:membership, user: owner, account: account, role: "owner") }

  let(:subscription) { OpenStruct.new(id: account.stripe_subscription_id) }
  let(:event) { OpenStruct.new(type: "customer.subscription.deleted", data: OpenStruct.new(object: subscription)) }

  describe ".call" do
    it "updates subscription_status to canceled" do
      described_class.call(event)

      expect(account.reload.subscription_status).to be_nil
    end

    it "downgrades account to free plan" do
      described_class.call(event)

      expect(account.reload.plan).to eq("free")
    end

    it "clears stripe_subscription_id" do
      described_class.call(event)

      expect(account.reload.stripe_subscription_id).to be_nil
    end

    it "sends notification to account owner" do
      expect {
        described_class.call(event)
      }.to change(Noticed::Event, :count).by(1)
    end

    it "logs the cancellation" do
      allow(Rails.logger).to receive(:info)

      described_class.call(event)

      expect(Rails.logger).to have_received(:info).with(/Subscription.*canceled for account #{account.id}/)
    end

    context "when account is already canceled" do
      before { account.update!(subscription_status: "canceled") }

      it "does not send duplicate notification" do
        expect {
          described_class.call(event)
        }.not_to change(Noticed::Event, :count)
      end
    end

    context "when account is not found" do
      let(:subscription) { OpenStruct.new(id: "sub_unknown") }

      it "returns false" do
        result = described_class.call(event)

        expect(result).to be false
      end
    end
  end
end
