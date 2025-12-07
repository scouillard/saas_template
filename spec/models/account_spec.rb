require "rails_helper"

RSpec.describe Account, type: :model do
  describe "enums" do
    it "defines plan enum with string values" do
      expect(described_class.new).to define_enum_for(:plan)
        .with_values(free: "free", pro: "pro", enterprise: "enterprise")
        .with_prefix(true)
        .backed_by_column_of_type(:string)
    end

    it "defines subscription_status enum with string values and prefix" do
      expect(described_class.new).to define_enum_for(:subscription_status)
        .with_values(
          incomplete: "incomplete",
          incomplete_expired: "incomplete_expired",
          trialing: "trialing",
          active: "active",
          past_due: "past_due",
          canceled: "canceled",
          unpaid: "unpaid",
          canceling: "canceling"
        )
        .with_prefix(true)
        .backed_by_column_of_type(:string)
    end
  end

  describe "#subscription_active?" do
    it "returns true when status is active" do
      account = build(:account, subscription_status: :active)
      expect(account.subscription_active?).to be true
    end

    it "returns true when status is trialing" do
      account = build(:account, subscription_status: :trialing)
      expect(account.subscription_active?).to be true
    end

    it "returns false when status is past_due" do
      account = build(:account, subscription_status: :past_due)
      expect(account.subscription_active?).to be false
    end

    it "returns false when status is canceled" do
      account = build(:account, subscription_status: :canceled)
      expect(account.subscription_active?).to be false
    end

    it "returns false when status is nil" do
      account = build(:account, subscription_status: nil)
      expect(account.subscription_active?).to be false
    end
  end

  describe "#subscription_canceling?" do
    it "returns true when status is canceling" do
      account = build(:account, subscription_status: :canceling)
      expect(account.subscription_canceling?).to be true
    end

    it "returns false when status is active" do
      account = build(:account, subscription_status: :active)
      expect(account.subscription_canceling?).to be false
    end

    it "returns false when status is nil" do
      account = build(:account, subscription_status: nil)
      expect(account.subscription_canceling?).to be false
    end
  end

  describe "#can_reactivate?" do
    it "returns true when canceling with future period end" do
      account = build(:account,
        subscription_status: :canceling,
        current_period_ends_at: 1.month.from_now
      )
      expect(account.can_reactivate?).to be true
    end

    it "returns false when canceling with past period end" do
      account = build(:account,
        subscription_status: :canceling,
        current_period_ends_at: 1.day.ago
      )
      expect(account.can_reactivate?).to be false
    end

    it "returns false when active" do
      account = build(:account,
        subscription_status: :active,
        current_period_ends_at: 1.month.from_now
      )
      expect(account.can_reactivate?).to be false
    end

    it "returns falsey when current_period_ends_at is nil" do
      account = build(:account,
        subscription_status: :canceling,
        current_period_ends_at: nil
      )
      expect(account).not_to be_can_reactivate
    end
  end

  describe "#past_due?" do
    it "returns true when status is past_due" do
      account = build(:account, subscription_status: :past_due)
      expect(account.past_due?).to be true
    end

    it "returns false when status is active" do
      account = build(:account, subscription_status: :active)
      expect(account.past_due?).to be false
    end
  end

  describe "#canceled?" do
    it "returns true when status is canceled" do
      account = build(:account, subscription_status: :canceled)
      expect(account.canceled?).to be true
    end

    it "returns false when status is active" do
      account = build(:account, subscription_status: :active)
      expect(account.canceled?).to be false
    end
  end

  describe "#active_subscription?" do
    it "returns true when status is active" do
      account = build(:account, subscription_status: :active)
      expect(account.active_subscription?).to be true
    end

    it "returns false when status is trialing" do
      account = build(:account, subscription_status: :trialing)
      expect(account.active_subscription?).to be false
    end

    it "returns false when status is nil" do
      account = build(:account, subscription_status: nil)
      expect(account.active_subscription?).to be false
    end
  end

  describe "#can_change_plan?" do
    it "returns true when subscription is active and has stripe_subscription_id" do
      account = build(:account, :with_stripe, subscription_status: :active)
      expect(account.can_change_plan?).to be true
    end

    it "returns true when subscription is trialing and has stripe_subscription_id" do
      account = build(:account, :with_stripe, subscription_status: :trialing)
      expect(account.can_change_plan?).to be true
    end

    it "returns false when subscription is active but no stripe_subscription_id" do
      account = build(:account, subscription_status: :active, stripe_subscription_id: nil)
      expect(account.can_change_plan?).to be false
    end

    it "returns false when has stripe_subscription_id but status is past_due" do
      account = build(:account, :with_stripe, subscription_status: :past_due)
      expect(account.can_change_plan?).to be false
    end
  end

  describe "#upgrading_to?" do
    let(:account) { build(:account, plan: :pro) }

    it "returns true when target plan has higher monthly price" do
      expect(account.upgrading_to?("enterprise")).to be true
    end

    it "returns false when target plan has lower monthly price" do
      expect(account.upgrading_to?("free")).to be false
    end

    it "returns false when target plan is same as current" do
      expect(account.upgrading_to?("pro")).to be false
    end

    it "returns false when target plan does not exist" do
      expect(account.upgrading_to?("nonexistent")).to be false
    end
  end

  describe "#downgrading_to?" do
    let(:account) { build(:account, plan: :pro) }

    it "returns true when target plan has lower monthly price" do
      expect(account.downgrading_to?("free")).to be true
    end

    it "returns false when target plan has higher monthly price" do
      expect(account.downgrading_to?("enterprise")).to be false
    end

    it "returns false when target plan is same as current" do
      expect(account.downgrading_to?("pro")).to be false
    end

    it "returns false when target plan does not exist" do
      expect(account.downgrading_to?("nonexistent")).to be false
    end
  end

  describe "#billing_interval" do
    it "returns nil when no stripe_subscription_id" do
      account = build(:account, stripe_subscription_id: nil)
      expect(account.billing_interval).to be_nil
    end
  end

  describe "#determine_interval_from_price_id" do
    let(:account) { build(:account) }

    it "returns nil for blank price_id" do
      expect(account.determine_interval_from_price_id(nil)).to be_nil
      expect(account.determine_interval_from_price_id("")).to be_nil
    end

    it "returns nil for unrecognized price_id" do
      expect(account.determine_interval_from_price_id("unknown_price")).to be_nil
    end
  end

  describe "#sync_subscription" do
    let(:account) { create(:account, :with_stripe, plan: :free) }
    let(:subscription) do
      double(
        id: "sub_123",
        status: "active",
        start_date: 1.day.ago.to_i,
        current_period_end: 1.month.from_now.to_i,
        cancel_at: nil,
        items: double(data: [ double(price: double(id: "price_pro")) ])
      )
    end

    before do
      allow(account).to receive(:price_id_to_plan).and_return({ "price_pro" => "pro" })
    end

    it "updates subscription fields" do
      account.sync_subscription(subscription)

      expect(account.stripe_subscription_id).to eq("sub_123")
      expect(account.subscription_status).to eq("active")
      expect(account.plan).to eq("pro")
      expect(account.subscription_started_at).to be_present
      expect(account.current_period_ends_at).to be_present
    end

    context "when cancel_at is present" do
      let(:cancel_time) { 2.months.from_now.to_i }
      let(:subscription) do
        double(
          id: "sub_123",
          status: "active",
          start_date: 1.day.ago.to_i,
          current_period_end: 1.month.from_now.to_i,
          cancel_at: cancel_time,
          items: double(data: [ double(price: double(id: "price_pro")) ])
        )
      end

      it "sets subscription_ends_at" do
        account.sync_subscription(subscription)

        expect(account.subscription_ends_at).to be_within(1.second).of(Time.zone.at(cancel_time))
      end
    end

    context "when price_id is not recognized" do
      let(:subscription) do
        double(
          id: "sub_123",
          status: "active",
          start_date: 1.day.ago.to_i,
          current_period_end: 1.month.from_now.to_i,
          cancel_at: nil,
          items: double(data: [ double(price: double(id: "price_unknown")) ])
        )
      end

      it "keeps the current plan" do
        account.update!(plan: :pro)
        account.sync_subscription(subscription)

        expect(account.plan).to eq("pro")
      end
    end
  end

  describe "#cancel_subscription" do
    let(:account) { create(:account, :with_stripe, plan: :pro, subscription_status: :active) }
    let(:ended_at) { Time.now.to_i }
    let(:subscription) do
      double(
        ended_at: ended_at,
        current_period_end: 1.month.from_now.to_i
      )
    end

    it "sets status to canceled and plan to free" do
      account.cancel_subscription(subscription)

      expect(account.subscription_status).to eq("canceled")
      expect(account.plan).to eq("free")
      expect(account.subscription_ends_at).to be_within(1.second).of(Time.zone.at(ended_at))
    end

    context "when ended_at is nil" do
      let(:subscription) do
        double(
          ended_at: nil,
          current_period_end: 1.month.from_now.to_i
        )
      end

      it "uses current_period_end for subscription_ends_at" do
        account.cancel_subscription(subscription)

        expect(account.subscription_ends_at).to be_within(1.second).of(Time.zone.at(subscription.current_period_end))
      end
    end
  end

  describe "#update_billing_period" do
    let(:account) { create(:account, :with_stripe, plan: :pro, subscription_status: :past_due) }
    let(:new_period_end) { 1.month.from_now.to_i }
    let(:subscription) { double(current_period_end: new_period_end) }

    it "sets status to active and updates current_period_ends_at" do
      account.update_billing_period(subscription)

      expect(account.subscription_status).to eq("active")
      expect(account.current_period_ends_at).to be_within(1.second).of(Time.zone.at(new_period_end))
    end
  end

  describe "#determine_plan_from_price_id" do
    let(:account) { create(:account) }

    before do
      allow(account).to receive(:price_id_to_plan).and_return({
        "price_pro" => "pro",
        "price_enterprise" => "enterprise"
      })
    end

    it "returns pro for pro price id" do
      expect(account.determine_plan_from_price_id("price_pro")).to eq("pro")
    end

    it "returns enterprise for enterprise price id" do
      expect(account.determine_plan_from_price_id("price_enterprise")).to eq("enterprise")
    end

    it "returns nil for unknown price id" do
      expect(account.determine_plan_from_price_id("price_unknown")).to be_nil
    end
  end
end
