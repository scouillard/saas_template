require "rails_helper"

RSpec.describe Plan, type: :model do
  describe ".all" do
    it "loads plans from config/plans.yml" do
      plans = described_class.all

      expect(plans).to be_an(Array)
      expect(plans).not_to be_empty
      expect(plans.first).to be_a(described_class)
    end

    it "caches the plans" do
      first_call = described_class.all
      second_call = described_class.all

      expect(first_call.object_id).to eq(second_call.object_id)
    end
  end

  describe ".find" do
    it "finds a plan by name (case-insensitive)" do
      plan = described_class.find("starter")

      expect(plan).to be_a(described_class)
      expect(plan.name).to eq("Starter")
    end

    it "returns nil when plan not found" do
      plan = described_class.find("nonexistent")

      expect(plan).to be_nil
    end
  end

  describe ".find!" do
    it "finds a plan by name" do
      plan = described_class.find!("pro")

      expect(plan.name).to eq("Pro")
    end

    it "raises ActiveRecord::RecordNotFound when plan not found" do
      expect { described_class.find!("nonexistent") }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "attributes" do
    subject(:plan) { described_class.find("pro") }

    it "has name and description" do
      expect(plan.name).to eq("Pro")
      expect(plan.description).to be_present
    end

    it "has price and stripe attributes" do
      expect(plan.monthly_price).to be_a(Integer)
      expect(plan.annual_price).to be_a(Integer)
      expect(plan.stripe_price_id).to be_a(Hash)
      expect(plan.bullet_points).to be_an(Array)
    end
  end

  describe "#recommended?" do
    it "returns true for recommended plan" do
      plan = described_class.find("pro")

      expect(plan.recommended?).to be true
    end

    it "returns false for non-recommended plan" do
      plan = described_class.find("starter")

      expect(plan.recommended?).to be false
    end
  end

  describe "#monthly_price_dollars" do
    it "converts cents to dollars" do
      plan = described_class.find("starter")

      expect(plan.monthly_price_dollars).to eq(9.0)
    end
  end

  describe "#annual_price_dollars" do
    it "converts cents to dollars" do
      plan = described_class.find("starter")

      expect(plan.annual_price_dollars).to eq(90.0)
    end
  end

  describe "#annual_monthly_price" do
    it "calculates monthly equivalent of annual price in cents" do
      plan = described_class.find("starter")

      expect(plan.annual_monthly_price).to eq(750)
    end
  end

  describe "#annual_monthly_price_dollars" do
    it "calculates monthly equivalent of annual price in dollars" do
      plan = described_class.find("starter")

      expect(plan.annual_monthly_price_dollars).to eq(7.5)
    end
  end

  describe "#annual_savings_percent" do
    it "calculates percentage saved with annual billing" do
      plan = described_class.find("starter")

      expect(plan.annual_savings_percent).to eq(17)
    end

    it "returns 0 when monthly price is zero" do
      plan = described_class.new(monthly_price: 0, annual_price: 0)

      expect(plan.annual_savings_percent).to eq(0)
    end
  end
end
