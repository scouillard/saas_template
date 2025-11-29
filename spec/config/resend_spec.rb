# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Resend configuration" do
  describe "initializer" do
    it "configures Resend API key from environment" do
      expect(Resend.api_key).to eq(ENV.fetch("RESEND_API_KEY", nil))
    end

    context "when API key is set" do
      before { Resend.api_key = "re_test_key" }
      after { Resend.api_key = nil }

      it "stores the API key" do
        expect(Resend.api_key).to eq("re_test_key")
      end
    end
  end

  describe "production environment" do
    it "configures resend as delivery method in production.rb" do
      production_config = File.read(Rails.root.join("config/environments/production.rb"))
      expect(production_config).to include("config.action_mailer.delivery_method = :resend")
    end
  end

  describe "development environment" do
    it "configures letter_opener as delivery method in development.rb" do
      development_config = File.read(Rails.root.join("config/environments/development.rb"))
      expect(development_config).to include("config.action_mailer.delivery_method = :letter_opener")
    end
  end

  describe "test environment" do
    it "uses test delivery method" do
      expect(ActionMailer::Base.delivery_method).to eq(:test)
    end
  end
end
