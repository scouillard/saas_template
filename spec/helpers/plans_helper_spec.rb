require "rails_helper"

RSpec.describe PlansHelper, type: :helper do
  describe "#format_plan_price" do
    it "returns 'Free' for zero price" do
      expect(helper.format_plan_price(0)).to eq("Free")
    end

    it "formats whole dollar amounts without decimals" do
      expect(helper.format_plan_price(2900)).to eq("$29")
    end

    it "formats amounts with cents" do
      expect(helper.format_plan_price(2950)).to eq("$29.50")
    end

    it "formats large amounts" do
      expect(helper.format_plan_price(29000)).to eq("$290")
    end
  end

  describe "#annual_monthly_price" do
    it "calculates monthly equivalent of annual price" do
      plan = Plan.find("pro")
      # $290/year / 12 = $24.17 -> truncates to 24
      expect(helper.annual_monthly_price(plan)).to eq(2416)
    end
  end
end
