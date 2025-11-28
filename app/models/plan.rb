class Plan
  class PlanNotFound < StandardError; end

  attr_reader :key, :name, :description, :monthly_price, :annual_price,
              :bullet_points, :recommended, :stripe_price_id,
              :stripe_annual_price_id, :trial_days, :limits, :cta_text, :badge

  def initialize(key, attributes)
    @key = key
    @name = attributes["name"]
    @description = attributes["description"]
    @monthly_price = attributes["monthly_price"]
    @annual_price = attributes["annual_price"]
    @bullet_points = attributes["bullet_points"] || []
    @recommended = attributes["recommended"] || false
    @stripe_price_id = attributes["stripe_price_id"]
    @stripe_annual_price_id = attributes["stripe_annual_price_id"]
    @trial_days = attributes["trial_days"] || 0
    @limits = attributes["limits"] || {}
    @cta_text = attributes["cta_text"] || "Get Started"
    @badge = attributes["badge"]
  end

  def self.all
    @all ||= load_plans
  end

  def self.find(key)
    plan = all.find { |p| p.key == key.to_s }
    raise PlanNotFound, "Plan '#{key}' not found" unless plan
    plan
  end

  def self.recommended
    all.find(&:recommended)
  end

  def self.reload!
    @all = nil
  end

  def monthly_price_display
    return "Free" if monthly_price.zero?
    "$#{monthly_price}"
  end

  def annual_price_display
    return "Free" if annual_price.zero?
    "$#{annual_price}"
  end

  def annual_monthly_equivalent
    return 0 if annual_price.zero?
    (annual_price / 12.0).round(2)
  end

  def annual_discount_percent
    return 0 if monthly_price.zero? || annual_price.zero?
    monthly_total = monthly_price * 12
    ((monthly_total - annual_price) / monthly_total.to_f * 100).round
  end

  def recommended?
    recommended
  end

  def free?
    monthly_price.zero? && annual_price.zero?
  end

  private_class_method def self.load_plans
    config_path = Rails.root.join("config", "plans.yml")
    plans_data = YAML.load_file(config_path)
    plans_data.map { |key, attrs| new(key, attrs) }
  end
end
