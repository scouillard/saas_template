require "rails_helper"

RSpec.describe Account, type: :model do
  describe "#activate_subscription" do
    let(:account) { create(:account) }

    it "updates stripe fields and plan" do
      account.activate_subscription(
        customer_id: "cus_test123",
        subscription_id: "sub_test456",
        plan: "pro"
      )

      expect(account.stripe_customer_id).to eq("cus_test123")
      expect(account.stripe_subscription_id).to eq("sub_test456")
      expect(account.plan).to eq("pro")
      expect(account.subscription_started_at).to be_present
    end
  end

  describe "#cancel_subscription" do
    let(:account) { create(:account, :with_stripe, plan: "pro") }

    it "resets subscription fields and reverts to free plan" do
      account.cancel_subscription

      expect(account.stripe_subscription_id).to be_nil
      expect(account.plan).to eq("free")
      expect(account.subscription_ends_at).to be_present
    end
  end

  describe "#subscribed?" do
    it "returns true when account has active subscription" do
      account = create(:account, :with_stripe, plan: "pro")

      expect(account.subscribed?).to be true
    end

    it "returns false for free accounts" do
      account = create(:account, plan: "free")

      expect(account.subscribed?).to be false
    end
  end
end
