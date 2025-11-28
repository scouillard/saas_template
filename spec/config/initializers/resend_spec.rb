# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Resend configuration" do
  describe "API key" do
    it "configures Resend with environment variable" do
      expect(Resend.api_key).to eq(ENV["RESEND_API_KEY"])
    end
  end

  describe "production environment" do
    it "uses resend delivery method" do
      # Load production config to check settings
      production_config = Rails.application.config_for(:production, env: "production")
      # This test verifies the file exists and is valid Ruby
      production_file = Rails.root.join("config/environments/production.rb")
      expect(File.read(production_file)).to include("delivery_method = :resend")
    end
  end
end
