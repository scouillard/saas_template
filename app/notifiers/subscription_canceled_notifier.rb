class SubscriptionCanceledNotifier < Noticed::Event
  deliver_by :email, mailer: "BillingMailer", method: :subscription_canceled

  notification_methods do
    def message
      t(".message")
    end

    def url
      pricing_path
    end
  end
end
