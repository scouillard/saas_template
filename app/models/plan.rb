class Plan
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :id, :string
  attribute :name, :string
  attribute :description, :string
  attribute :monthly_price, :integer, default: 0
  attribute :annual_price, :integer, default: 0
  attribute :bullet_points, default: -> { [] }
  attribute :recommended, :boolean, default: false
  attribute :stripe_monthly_price_id, :string
  attribute :stripe_annual_price_id, :string
  attribute :features_limit, default: -> { {} }

  class << self
    def all
      @all ||= load_plans
    end

    def find(id)
      all.find { |plan| plan.id == id.to_s }
    end

    def recommended
      all.find(&:recommended?)
    end

    def reload!
      @all = nil
    end

    private

    def load_plans
      yaml_path = Rails.root.join("config/plans.yml")
      raise "Plans configuration not found at #{yaml_path}" unless yaml_path.exist?

      plans_data = YAML.load_file(yaml_path)
      raise "Plans configuration is empty or malformed" if plans_data.blank?

      plans_data.map do |id, attrs|
        new(attrs.symbolize_keys.merge(id: id))
      end
    end
  end

  def recommended?
    recommended == true
  end

  def price_for(billing_period)
    case billing_period.to_sym
    when :monthly then monthly_price
    when :annual then annual_price
    else raise ArgumentError, "Invalid billing period: #{billing_period}"
    end
  end

  def stripe_price_id_for(billing_period)
    case billing_period.to_sym
    when :monthly then stripe_monthly_price_id
    when :annual then stripe_annual_price_id
    else raise ArgumentError, "Invalid billing period: #{billing_period}"
    end
  end

  def free?
    monthly_price.zero? && annual_price.zero?
  end
end
