class Subscriber < ApplicationRecord
  validates :email, presence: true,
                    uniqueness: { case_sensitive: false, message: "is already subscribed" },
                    format: { with: URI::MailTo::EMAIL_REGEXP }

  before_save :downcase_email

  private

  def downcase_email
    self.email = email.downcase
  end
end
