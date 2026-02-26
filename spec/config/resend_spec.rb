# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Resend configuration" do
  describe "initializer" do
    let(:initializer_path) { File.expand_path("../../config/initializers/resend.rb", __dir__) }

    it "exists" do
      expect(File.exist?(initializer_path)).to be true
    end

    it "configures Resend API key from environment" do
      content = File.read(initializer_path)
      expect(content).to include('Resend.api_key = ENV.fetch("RESEND_API_KEY", nil)')
    end
  end

  describe "production mailer configuration" do
    let(:production_file) { File.expand_path("../../config/environments/production.rb", __dir__) }

    it "uses resend delivery method" do
      content = File.read(production_file)
      expect(content).to include("config.action_mailer.delivery_method = :resend")
    end
  end

  describe "environment sample" do
    let(:env_sample_path) { File.expand_path("../../.env.sample", __dir__) }

    it "includes RESEND_API_KEY placeholder" do
      content = File.read(env_sample_path)
      expect(content).to include("RESEND_API_KEY=")
    end
  end
end
