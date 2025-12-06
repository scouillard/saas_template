class Task < ApplicationRecord
  STATUSES = %w[pending in_progress completed].freeze

  belongs_to :project

  validates :name, presence: true
  validates :status, inclusion: { in: STATUSES }

  def restart!
    update!(status: "pending")
  end
end
