class PaymentFailedNotifier < Noticed::Event
  deliver_by :email, mailer: "BillingMailer", method: :payment_failed

  notification_methods do
    def message
      t(".message")
    end

    def url
      billing_path
    end
  end
end
