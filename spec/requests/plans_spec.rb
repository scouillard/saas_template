require "rails_helper"

RSpec.describe "Plans", type: :request do
  let(:plans_fixture) { Rails.root.join("spec/fixtures/files/plans.yml") }

  before do
    allow(Plan).to receive(:config_path).and_return(plans_fixture)
    Plan.reload!
  end

  describe "GET /plan" do
    it "renders the pricing page" do
      get plan_path

      expect(response).to have_http_status(:ok)
    end

    it "displays all active plans" do
      get plan_path

      expect(response.body).to include("Starter")
      expect(response.body).to include("Pro")
      expect(response.body).to include("Enterprise")
    end

    it "displays plan prices" do
      get plan_path

      expect(response.body).to include("$9")
      expect(response.body).to include("$29")
      expect(response.body).to include("$99")
    end

    it "highlights the recommended plan" do
      get plan_path

      expect(response.body).to include("recommended")
    end

    it "includes monthly/annual toggle" do
      get plan_path

      expect(response.body).to include("Monthly")
      expect(response.body).to include("Annual")
    end
  end
end
