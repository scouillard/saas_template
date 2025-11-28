require "rails_helper"

RSpec.describe Plan, type: :model do
  before { described_class.reload! }

  describe ".all" do
    it "loads plans from YAML configuration" do
      plans = described_class.all
      expect(plans).to be_an(Array)
      expect(plans).not_to be_empty
    end

    it "returns Plan instances" do
      plans = described_class.all
      expect(plans).to all(be_a(described_class))
    end

    it "memoizes the loaded plans" do
      first_call = described_class.all
      second_call = described_class.all
      expect(first_call).to equal(second_call)
    end
  end

  describe ".find" do
    it "returns the plan with matching id" do
      plan = described_class.find("starter")
      expect(plan).to be_present
      expect(plan.id).to eq("starter")
    end

    it "returns nil for non-existent plan" do
      plan = described_class.find("nonexistent")
      expect(plan).to be_nil
    end

    it "accepts symbol ids" do
      plan = described_class.find(:starter)
      expect(plan).to be_present
    end
  end

  describe ".recommended" do
    it "returns the recommended plan" do
      recommended = described_class.recommended
      expect(recommended).to be_present
      expect(recommended.recommended?).to be true
    end
  end

  describe "attributes" do
    let(:plan) { described_class.find("pro") }

    it "has id and name" do
      expect(plan.id).to eq("pro")
      expect(plan.name).to eq("Pro")
      expect(plan.description).to be_present
    end

    it "has pricing and features" do
      expect(plan.monthly_price).to be_a(Integer)
      expect(plan.annual_price).to be_a(Integer)
      expect(plan.bullet_points).to be_an(Array)
    end
  end

  describe "#recommended?" do
    it "returns true for recommended plan" do
      plan = described_class.recommended
      expect(plan.recommended?).to be true
    end

    it "returns false for non-recommended plans" do
      plan = described_class.find("starter")
      expect(plan.recommended?).to be false
    end
  end

  describe "#price_for" do
    let(:plan) { described_class.find("pro") }

    it "returns monthly price for :monthly" do
      expect(plan.price_for(:monthly)).to eq(plan.monthly_price)
    end

    it "returns annual price for :annual" do
      expect(plan.price_for(:annual)).to eq(plan.annual_price)
    end

    it "raises for invalid billing period" do
      expect { plan.price_for(:invalid) }.to raise_error(ArgumentError)
    end
  end

  describe "#stripe_price_id_for" do
    let(:plan) { described_class.find("pro") }

    it "returns monthly stripe price id for :monthly" do
      expect(plan.stripe_price_id_for(:monthly)).to eq(plan.stripe_monthly_price_id)
    end

    it "returns annual stripe price id for :annual" do
      expect(plan.stripe_price_id_for(:annual)).to eq(plan.stripe_annual_price_id)
    end

    it "raises for invalid billing period" do
      expect { plan.stripe_price_id_for(:invalid) }.to raise_error(ArgumentError)
    end
  end

  describe "#free?" do
    it "returns true for free plans" do
      plan = described_class.find("starter")
      expect(plan.free?).to be true
    end

    it "returns false for paid plans" do
      plan = described_class.find("pro")
      expect(plan.free?).to be false
    end
  end
end
