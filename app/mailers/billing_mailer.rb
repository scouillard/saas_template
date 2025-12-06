class BillingMailer < ApplicationMailer
  def payment_failed(recipient, notification)
    @account = notification.event.params[:account]
    @recipient = recipient

    mail(
      to: recipient.email,
      subject: "Action required: Payment failed"
    )
  end

  def subscription_canceled(recipient, notification)
    @account = notification.event.params[:account]
    @recipient = recipient

    mail(
      to: recipient.email,
      subject: "Your subscription has been canceled"
    )
  end
end
