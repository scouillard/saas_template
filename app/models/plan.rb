class Plan
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string
  attribute :description, :string
  attribute :monthly_price, :integer
  attribute :annual_price, :integer
  attribute :stripe_price_id
  attribute :bullet_points
  attribute :recommended, :boolean, default: false

  class << self
    def all
      @all ||= load_plans
    end

    def find(name)
      all.find { |plan| plan.name.downcase == name.to_s.downcase }
    end

    def find!(name)
      find(name) || raise(ActiveRecord::RecordNotFound, "Plan '#{name}' not found")
    end

    def reload!
      @all = nil
      all
    end

    private

    def load_plans
      yaml = YAML.load_file(Rails.root.join("config/plans.yml"))
      yaml["plans"].map { |attrs| new(attrs.symbolize_keys) }
    end
  end

  def recommended?
    recommended
  end

  def monthly_price_dollars
    monthly_price / 100.0
  end

  def annual_price_dollars
    annual_price / 100.0
  end

  def annual_monthly_price
    annual_price / 12
  end

  def annual_monthly_price_dollars
    annual_monthly_price / 100.0
  end

  def annual_savings_percent
    return 0 if monthly_price.zero?

    full_annual = monthly_price * 12
    savings = full_annual - annual_price
    ((savings.to_f / full_annual) * 100).round
  end
end
