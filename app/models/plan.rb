class Plan
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :description, :string
  attribute :monthly_price, :integer
  attribute :annual_price, :integer
  attribute :stripe_monthly_price_id, :string
  attribute :stripe_annual_price_id, :string
  attribute :trial_days, :integer, default: 0
  attribute :badge_text, :string
  attribute :cta_text, :string, default: "Get Started"
  attribute :position, :integer, default: 0
  attribute :bullet_points, default: []
  attribute :features, default: {}

  class << self
    def all
      @all ||= load_plans
    end

    def find_by_name(name)
      all.find { |plan| plan.name.downcase == name.to_s.downcase }
    end

    def reload!
      @all = nil
      all
    end

    private

    def load_plans
      yaml_path = Rails.root.join("config", "plans.yml")
      plans_data = YAML.load_file(yaml_path)
      plans_data.map { |data| new(data) }.sort_by(&:position)
    end
  end

  def price_for(billing_period)
    billing_period.to_sym == :annual ? annual_price : monthly_price
  end

  def stripe_price_id_for(billing_period)
    billing_period.to_sym == :annual ? stripe_annual_price_id : stripe_monthly_price_id
  end

  def badge?
    badge_text.present?
  end

  def annual_savings
    return 0 if monthly_price.nil? || annual_price.nil?
    (monthly_price * 12) - annual_price
  end

  def annual_savings_percentage
    return 0 if monthly_price.nil? || monthly_price.zero?
    ((annual_savings.to_f / (monthly_price * 12)) * 100).round
  end
end
