require "rails_helper"

RSpec.describe Stripe::WebhookHandler do
  describe "#call" do
    let(:account) { create(:account, :with_stripe) }

    it "dispatches checkout.session.completed to CheckoutCompletedHandler" do
      event = stripe_event("checkout.session.completed", {
        customer: account.stripe_customer_id,
        subscription: "sub_new",
        client_reference_id: account.id.to_s
      })

      expect(Stripe::CheckoutCompletedHandler).to receive(:new).with(event).and_call_original

      described_class.new(event).call
    end

    it "dispatches customer.subscription.created to SubscriptionCreatedHandler" do
      event = stripe_event("customer.subscription.created", {
        id: account.stripe_subscription_id,
        customer: account.stripe_customer_id,
        status: "active",
        current_period_start: Time.current.to_i,
        current_period_end: 1.month.from_now.to_i,
        items: { data: [ { price: { id: "price_pro_monthly" } } ] }
      })

      expect(Stripe::SubscriptionCreatedHandler).to receive(:new).with(event).and_call_original

      described_class.new(event).call
    end

    it "dispatches customer.subscription.updated to SubscriptionUpdatedHandler" do
      event = stripe_event("customer.subscription.updated", {
        id: account.stripe_subscription_id,
        customer: account.stripe_customer_id,
        status: "active",
        current_period_start: Time.current.to_i,
        current_period_end: 1.month.from_now.to_i,
        items: { data: [ { price: { id: "price_pro_monthly" } } ] }
      })

      expect(Stripe::SubscriptionUpdatedHandler).to receive(:new).with(event).and_call_original

      described_class.new(event).call
    end

    it "dispatches customer.subscription.deleted to SubscriptionDeletedHandler" do
      event = stripe_event("customer.subscription.deleted", {
        id: account.stripe_subscription_id,
        customer: account.stripe_customer_id,
        current_period_end: 1.month.from_now.to_i
      })

      expect(Stripe::SubscriptionDeletedHandler).to receive(:new).with(event).and_call_original

      described_class.new(event).call
    end

    it "dispatches invoice.paid to InvoicePaidHandler" do
      event = stripe_event("invoice.paid", {
        customer: account.stripe_customer_id,
        subscription: account.stripe_subscription_id
      })

      expect(Stripe::InvoicePaidHandler).to receive(:new).with(event).and_call_original

      described_class.new(event).call
    end

    it "dispatches invoice.payment_failed to InvoicePaymentFailedHandler" do
      event = stripe_event("invoice.payment_failed", {
        customer: account.stripe_customer_id,
        subscription: account.stripe_subscription_id
      })

      expect(Stripe::InvoicePaymentFailedHandler).to receive(:new).with(event).and_call_original

      described_class.new(event).call
    end

    it "returns false for unknown event types" do
      event = stripe_event("unknown.event", {})

      result = described_class.new(event).call

      expect(result).to be false
    end
  end

  private

  def stripe_event(type, data)
    Stripe::Event.construct_from({
      id: "evt_#{SecureRandom.hex(12)}",
      type: type,
      data: { object: data }
    })
  end
end
