class Account < ApplicationRecord
  enum :plan, { free: "free" }

  has_many :memberships, dependent: :destroy
  has_many :users, through: :memberships

  def subscription_active?
    subscription_status == "active"
  end

  def subscription_past_due?
    subscription_status == "past_due"
  end

  def subscription_canceled?
    subscription_status == "canceled"
  end

  def subscription_incomplete?
    subscription_status == "incomplete"
  end

  def subscribed?
    subscription_active? || subscription_past_due?
  end
end
