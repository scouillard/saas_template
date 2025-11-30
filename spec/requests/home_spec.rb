require "rails_helper"

RSpec.describe "Home", type: :request do
  describe "GET /" do
    it "renders the homepage" do
      get root_path
      expect(response).to have_http_status(:ok)
    end

    it "includes the hero section" do
      get root_path
      expect(response.body).to include("Build Your Product")
      expect(response.body).to include("Get Started Free")
    end

    it "includes the features section" do
      get root_path
      expect(response.body).to include("Everything You Need")
      expect(response.body).to include("Authentication")
    end

    it "includes the pricing section" do
      get root_path
      expect(response.body).to include("Simple, Transparent Pricing")
      expect(response.body).to include("Monthly")
      expect(response.body).to include("Annual")
    end

    it "includes the FAQ section" do
      get root_path
      expect(response.body).to include("Frequently Asked Questions")
    end

    it "includes the problem section" do
      get root_path
      expect(response.body).to include("The Problem")
      expect(response.body).to include("Why we built this")
    end

    it "includes SEO meta tags" do
      get root_path
      expect(response.body).to include('meta name="description"')
      expect(response.body).to include('property="og:title"')
      expect(response.body).to include('rel="canonical"')
    end

    it "includes the footer with sitemap links" do
      get root_path
      expect(response.body).to include("Product")
      expect(response.body).to include("Company")
      expect(response.body).to include("Legal")
      expect(response.body).to include("Terms of Service")
      expect(response.body).to include("Privacy Policy")
    end
  end
end
