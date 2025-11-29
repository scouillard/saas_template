require "rails_helper"

RSpec.describe Plan, type: :model do
  let(:plans_fixture) { Rails.root.join("spec/fixtures/files/plans.yml") }

  before do
    allow(Plan).to receive(:config_path).and_return(plans_fixture)
    Plan.reload!
  end

  describe ".all" do
    it "loads all plans from YAML" do
      plans = Plan.all

      expect(plans.size).to eq(3)
      expect(plans.map(&:id)).to contain_exactly("starter", "pro", "enterprise")
    end

    it "returns plans sorted by position" do
      plans = Plan.all

      expect(plans.map(&:id)).to eq(%w[starter pro enterprise])
    end
  end

  describe ".find" do
    it "returns the plan with the given id" do
      plan = Plan.find("pro")

      expect(plan.id).to eq("pro")
      expect(plan.name).to eq("Pro")
    end
  end

  describe ".recommended" do
    it "returns the recommended plan" do
      plan = Plan.recommended

      expect(plan.id).to eq("pro")
      expect(plan.recommended).to be true
    end
  end

  describe ".active" do
    it "returns only active plans" do
      plans = Plan.active

      expect(plans).to all(have_attributes(active: true))
    end
  end

  describe "attributes" do
    let(:plan) { Plan.find("pro") }

    it "has all expected attributes" do
      expect(plan.name).to eq("Pro")
      expect(plan.description).to eq("Best for growing teams")
      expect(plan.monthly_price).to eq(29)
      expect(plan.annual_price).to eq(290)
      expect(plan.bullet_points).to include("Unlimited projects")
      expect(plan.recommended).to be true
      expect(plan.stripe_price_id).to eq("price_pro_monthly")
      expect(plan.stripe_annual_price_id).to eq("price_pro_annual")
      expect(plan.trial_days).to eq(14)
      expect(plan.position).to eq(2)
      expect(plan.active).to be true
    end
  end

  describe "#annual_savings" do
    it "calculates savings from annual billing" do
      plan = Plan.find("pro")

      # Monthly: 29 * 12 = 348, Annual: 290, Savings: 58
      expect(plan.annual_savings).to eq(58)
    end
  end

  describe "#annual_monthly_equivalent" do
    it "calculates monthly equivalent of annual price" do
      plan = Plan.find("pro")

      # 290 / 12 = 24.17 (rounded)
      expect(plan.annual_monthly_equivalent).to be_within(0.01).of(24.17)
    end
  end
end
