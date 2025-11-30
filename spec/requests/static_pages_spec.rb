require "rails_helper"

RSpec.describe "Static Pages", type: :request do
  describe "GET /privacy" do
    it "renders the privacy policy page" do
      get privacy_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Privacy Policy")
    end
  end

  describe "GET /terms" do
    it "renders the terms of service page" do
      get terms_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Terms of Service")
    end
  end
end
