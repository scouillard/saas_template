require "rails_helper"
require "ostruct"

RSpec.describe Stripe::SubscriptionUpdatedHandler do
  let(:account) { create(:account, :with_stripe, subscription_status: "active") }
  let(:current_period_end) { 1.month.from_now.to_i }

  let(:subscription) do
    OpenStruct.new(
      id: account.stripe_subscription_id,
      status: "past_due",
      current_period_end: current_period_end
    )
  end
  let(:event) { OpenStruct.new(type: "customer.subscription.updated", data: OpenStruct.new(object: subscription)) }

  describe ".call" do
    it "updates subscription_status from stripe" do
      described_class.call(event)

      expect(account.reload.subscription_status).to eq("past_due")
    end

    it "updates current_period_ends_at from stripe" do
      described_class.call(event)

      expect(account.reload.current_period_ends_at).to be_within(1.second).of(Time.zone.at(current_period_end))
    end

    it "logs the update" do
      allow(Rails.logger).to receive(:info)

      described_class.call(event)

      expect(Rails.logger).to have_received(:info).with(/Subscription.*updated to status: past_due/)
    end

    context "when account is not found" do
      let(:subscription) { OpenStruct.new(id: "sub_unknown", status: "past_due", current_period_end: current_period_end) }

      it "returns false" do
        result = described_class.call(event)

        expect(result).to be false
      end
    end
  end
end
