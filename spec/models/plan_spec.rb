require "rails_helper"

RSpec.describe Plan do
  before do
    described_class.reload!
  end

  describe ".all" do
    it "returns all plans from YAML" do
      plans = described_class.all

      expect(plans).to be_an(Array)
      expect(plans.length).to eq(3)
      expect(plans.map(&:key)).to contain_exactly("free", "pro", "enterprise")
    end

    it "caches the result" do
      first_call = described_class.all
      second_call = described_class.all

      expect(first_call).to equal(second_call)
    end
  end

  describe ".find" do
    it "returns the plan by key" do
      plan = described_class.find("pro")

      expect(plan.key).to eq("pro")
      expect(plan.name).to eq("Pro")
    end

    it "accepts symbol keys" do
      plan = described_class.find(:pro)

      expect(plan.key).to eq("pro")
    end

    it "raises PlanNotFound for invalid key" do
      expect { described_class.find("invalid") }.to raise_error(Plan::PlanNotFound, "Plan 'invalid' not found")
    end
  end

  describe ".recommended" do
    it "returns the recommended plan" do
      plan = described_class.recommended

      expect(plan.key).to eq("pro")
      expect(plan.recommended?).to be true
    end
  end

  describe ".reload!" do
    it "clears the cached plans" do
      first_call = described_class.all
      described_class.reload!
      second_call = described_class.all

      expect(first_call).not_to equal(second_call)
    end
  end

  describe "plan attributes" do
    let(:pro_plan) { described_class.find("pro") }
    let(:free_plan) { described_class.find("free") }

    it "loads name and description from YAML" do
      expect(pro_plan.name).to eq("Pro")
      expect(pro_plan.description).to eq("For growing teams")
    end

    it "loads pricing from YAML" do
      expect(pro_plan.monthly_price).to eq(29)
      expect(pro_plan.annual_price).to eq(290)
    end

    it "loads bullet_points from YAML" do
      expect(pro_plan.bullet_points).to include("Unlimited projects")
    end

    it "loads stripe IDs from YAML" do
      expect(pro_plan.stripe_price_id).to eq("price_pro_monthly")
      expect(pro_plan.stripe_annual_price_id).to eq("price_pro_annual")
    end

    it "loads recommended flag from YAML" do
      expect(pro_plan.recommended).to be true
    end

    it "loads limits hash" do
      expect(pro_plan.limits).to include("projects" => -1, "team_members" => 10)
    end
  end

  describe "#recommended?" do
    it "returns true for recommended plans" do
      plan = described_class.find("pro")
      expect(plan.recommended?).to be true
    end

    it "returns false for non-recommended plans" do
      plan = described_class.find("free")
      expect(plan.recommended?).to be false
    end
  end

  describe "#free?" do
    it "returns true when both prices are zero" do
      plan = described_class.find("free")
      expect(plan.free?).to be true
    end

    it "returns false when prices are non-zero" do
      plan = described_class.find("pro")
      expect(plan.free?).to be false
    end
  end

  describe "#annual_monthly_equivalent" do
    it "returns monthly equivalent of annual price" do
      plan = described_class.find("pro")
      expect(plan.annual_monthly_equivalent).to eq(24.17)
    end

    it "returns 0 for free plans" do
      plan = described_class.find("free")
      expect(plan.annual_monthly_equivalent).to eq(0)
    end
  end

  describe "#annual_discount_percent" do
    it "calculates the discount percentage" do
      plan = described_class.find("pro")
      # Monthly: $29 * 12 = $348, Annual: $290
      # Discount: ($348 - $290) / $348 = 16.67% ~ 17%
      expect(plan.annual_discount_percent).to eq(17)
    end

    it "returns 0 for free plans" do
      plan = described_class.find("free")
      expect(plan.annual_discount_percent).to eq(0)
    end
  end

  describe "#monthly_price_display" do
    it "returns formatted price" do
      plan = described_class.find("pro")
      expect(plan.monthly_price_display).to eq("$29")
    end

    it "returns 'Free' for free plans" do
      plan = described_class.find("free")
      expect(plan.monthly_price_display).to eq("Free")
    end
  end

  describe "#annual_price_display" do
    it "returns formatted price" do
      plan = described_class.find("pro")
      expect(plan.annual_price_display).to eq("$290")
    end

    it "returns 'Free' for free plans" do
      plan = described_class.find("free")
      expect(plan.annual_price_display).to eq("Free")
    end
  end
end
