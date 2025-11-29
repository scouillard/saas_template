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
  attribute :badge_text, :string
  attribute :cta_text, :string, default: "Get Started"
  attribute :trial_days, :integer
  attribute :stripe_monthly_price_id, :string
  attribute :stripe_annual_price_id, :string

  class << self
    def all
      @all ||= load_plans
    end

    def find(id)
      plan = find_by(id: id.to_s)
      raise ActiveRecord::RecordNotFound, "Plan '#{id}' not found" unless plan
      plan
    end

    def find_by(id: nil, name: nil)
      return all.find { |p| p.id == id.to_s } if id
      return all.find { |p| p.name == name } if name
      nil
    end

    def reload!
      @all = nil
      all
    end

    private

    def load_plans
      config_path = Rails.root.join("config", "plans.yml")
      plans_hash = YAML.load_file(config_path)

      plans_hash.map do |id, attrs|
        new(attrs.merge("id" => id))
      end
    end
  end

  def recommended?
    recommended
  end

  def free?
    monthly_price.zero? && annual_price.zero?
  end

  def annual_savings_percent
    return 0 if monthly_price.zero?
    yearly_if_monthly = monthly_price * 12
    ((yearly_if_monthly - annual_price).to_f / yearly_if_monthly * 100).round
  end
end
