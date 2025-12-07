require "rails_helper"

RSpec.describe BillingHelper, type: :helper do
  describe "#subscription_status_text" do
    let(:account) { build(:account) }

    context "when subscription_status is blank" do
      before { account.subscription_status = nil }

      it "returns 'No Subscription'" do
        expect(helper.subscription_status_text(account)).to eq("No Subscription")
      end
    end

    context "when subscription_status is active" do
      before { account.subscription_status = "active" }

      it "returns 'Active'" do
        expect(helper.subscription_status_text(account)).to eq("Active")
      end
    end

    context "when subscription_status is trialing" do
      before do
        account.subscription_status = "trialing"
        account.current_period_ends_at = Date.new(2025, 1, 15)
      end

      it "returns trial end date" do
        expect(helper.subscription_status_text(account)).to eq("Trial ends Jan 15, 2025")
      end
    end

    context "when subscription_status is canceled with future end date" do
      before do
        account.subscription_status = "canceled"
        account.current_period_ends_at = 1.month.from_now
      end

      it "returns cancellation date" do
        expect(helper.subscription_status_text(account)).to include("Cancels")
      end
    end

    context "when subscription_status is canceled with past end date" do
      before do
        account.subscription_status = "canceled"
        account.current_period_ends_at = 1.day.ago
      end

      it "returns 'Canceled'" do
        expect(helper.subscription_status_text(account)).to eq("Canceled")
      end
    end
  end
end
