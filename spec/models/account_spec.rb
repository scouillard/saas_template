require "rails_helper"

RSpec.describe Account, type: :model do
  describe "enums" do
    it "defines plan enum with string values" do
      expect(described_class.new).to define_enum_for(:plan)
        .with_values(free: "free", pro: "pro", enterprise: "enterprise")
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
          unpaid: "unpaid"
        )
        .with_prefix(true)
        .backed_by_column_of_type(:string)
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
