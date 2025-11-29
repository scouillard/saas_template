require "rails_helper"

RSpec.describe Plan, type: :model do
  before { described_class.reload! }

  describe ".all" do
    it "returns all plans from YAML config" do
      plans = described_class.all
      expect(plans).to be_an(Array)
      expect(plans).not_to be_empty
      expect(plans.first).to be_a(described_class)
    end

    it "caches the result" do
      first_call = described_class.all
      second_call = described_class.all
      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe ".find" do
    it "returns plan by id" do
      plan = described_class.find("free")
      expect(plan).to be_a(described_class)
      expect(plan.id).to eq("free")
    end

    it "raises error when plan not found" do
      expect { described_class.find("nonexistent") }
        .to raise_error(ActiveRecord::RecordNotFound, "Plan 'nonexistent' not found")
    end
  end

  describe ".find_by" do
    it "finds plan by id" do
      plan = described_class.find_by(id: "pro")
      expect(plan).to be_a(described_class)
      expect(plan.id).to eq("pro")
    end

    it "finds plan by name" do
      plan = described_class.find_by(name: "Pro")
      expect(plan).to be_a(described_class)
      expect(plan.name).to eq("Pro")
    end

    it "returns nil when not found" do
      expect(described_class.find_by(id: "nonexistent")).to be_nil
    end
  end

  describe "#recommended?" do
    it "returns true for recommended plan" do
      plan = described_class.find("pro")
      expect(plan.recommended?).to be true
    end

    it "returns false for non-recommended plan" do
      plan = described_class.find("free")
      expect(plan.recommended?).to be false
    end
  end

  describe "#free?" do
    it "returns true when both prices are zero" do
      plan = described_class.find("free")
      expect(plan.free?).to be true
    end

    it "returns false when prices are not zero" do
      plan = described_class.find("pro")
      expect(plan.free?).to be false
    end
  end

  describe "#annual_savings_percent" do
    it "calculates savings correctly" do
      plan = described_class.find("pro")
      # Pro: $29/month * 12 = $348/year, but annual is $290
      # Savings: (348 - 290) / 348 * 100 = 16.67%
      expect(plan.annual_savings_percent).to eq(17)
    end

    it "returns 0 for free plan" do
      plan = described_class.find("free")
      expect(plan.annual_savings_percent).to eq(0)
    end
  end

  describe "attributes" do
    let(:plan) { described_class.find("pro") }

    it "has basic attributes" do
      expect(plan.id).to eq("pro")
      expect(plan.name).to eq("Pro")
      expect(plan.description).to be_present
    end

    it "has pricing attributes" do
      expect(plan.monthly_price).to eq(2900)
      expect(plan.annual_price).to eq(29000)
      expect(plan.bullet_points).to be_an(Array)
    end

    it "has display attributes" do
      expect(plan.badge_text).to eq("Most Popular")
      expect(plan.cta_text).to eq("Start Free Trial")
      expect(plan.trial_days).to eq(14)
    end

    it "has Stripe price IDs" do
      expect(plan.stripe_monthly_price_id).to eq("price_pro_monthly")
      expect(plan.stripe_annual_price_id).to eq("price_pro_annual")
    end
  end
end
