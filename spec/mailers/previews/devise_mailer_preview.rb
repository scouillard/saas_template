# frozen_string_literal: true

class DeviseMailerPreview < ActionMailer::Preview
  def confirmation_instructions
    Devise::Mailer.confirmation_instructions(user, "fake-token")
  end

  def reset_password_instructions
    Devise::Mailer.reset_password_instructions(user, "fake-token")
  end

  def unlock_instructions
    Devise::Mailer.unlock_instructions(user, "fake-token")
  end

  def email_changed
    Devise::Mailer.email_changed(user)
  end

  def password_change
    Devise::Mailer.password_change(user)
  end

  private

  def user
    User.first || User.new(
      email: "preview@example.com",
      name: "Preview User"
    )
  end
end
