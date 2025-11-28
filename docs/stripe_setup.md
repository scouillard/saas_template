# Stripe Setup Guide

This guide covers how to configure Stripe Checkout for subscription billing.

## Prerequisites

- A Stripe account (sign up at https://stripe.com)
- Access to the Stripe Dashboard

## 1. Get API Keys

1. Log in to the [Stripe Dashboard](https://dashboard.stripe.com)
2. Navigate to **Developers > API keys**
3. Copy your keys:
   - **Publishable key** (starts with `pk_test_` or `pk_live_`)
   - **Secret key** (starts with `sk_test_` or `sk_live_`)
4. Add to your `.env` file:
   ```
   STRIPE_PUBLISHABLE_KEY=pk_test_...
   STRIPE_SECRET_KEY=sk_test_...
   ```

## 2. Create Products and Prices

### Create Products

1. Go to **Products** in the Stripe Dashboard
2. Click **Add product**
3. Create two products:

**Pro Plan**
- Name: Pro
- Description: For growing teams
- Pricing: $29/month (recurring)

**Business Plan**
- Name: Business
- Description: For larger organizations
- Pricing: $99/month (recurring)

### Get Price IDs

1. After creating each product, click on it to view details
2. Under **Pricing**, find the Price ID (starts with `price_`)
3. Add to your `.env` file:
   ```
   STRIPE_PRO_PRICE_ID=price_...
   STRIPE_BUSINESS_PRICE_ID=price_...
   ```

## 3. Set Up Webhooks

### Production

1. Go to **Developers > Webhooks**
2. Click **Add endpoint**
3. Enter your endpoint URL: `https://yourdomain.com/stripe/webhook`
4. Select events to listen to:
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`
5. Click **Add endpoint**
6. Copy the **Signing secret** (starts with `whsec_`)
7. Add to your `.env` file:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

### Local Development with Stripe CLI

1. Install the Stripe CLI: https://stripe.com/docs/stripe-cli
   ```bash
   # macOS
   brew install stripe/stripe-cli/stripe

   # Linux (Debian/Ubuntu)
   curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg
   echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee -a /etc/apt/sources.list.d/stripe.list
   sudo apt update
   sudo apt install stripe
   ```

2. Log in to Stripe:
   ```bash
   stripe login
   ```

3. Forward webhooks to your local server:
   ```bash
   stripe listen --forward-to localhost:3000/stripe/webhook
   ```

4. Copy the webhook signing secret from the CLI output and add to `.env`:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_...
   ```

## 4. Test Locally

### Start the webhook listener

In a terminal, run:
```bash
stripe listen --forward-to localhost:3000/stripe/webhook
```

### Test checkout flow

1. Start your Rails server: `bin/dev`
2. Log in to your app
3. Go to the Plan page
4. Click "Upgrade to Pro" or "Upgrade to Business"
5. Use test card: `4242 4242 4242 4242`
   - Any future expiration date
   - Any CVC
   - Any billing details

### Trigger test events

```bash
# Trigger a subscription created event
stripe trigger customer.subscription.created

# Trigger a payment failed event
stripe trigger invoice.payment_failed
```

## 5. Environment Variables Summary

```
# Required for Stripe integration
STRIPE_PUBLISHABLE_KEY=pk_test_...
STRIPE_SECRET_KEY=sk_test_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PRO_PRICE_ID=price_...
STRIPE_BUSINESS_PRICE_ID=price_...
```

## Troubleshooting

### Webhook signature verification failed

- Ensure `STRIPE_WEBHOOK_SECRET` matches the signing secret from the webhook endpoint or Stripe CLI
- For local development, use the secret provided by `stripe listen`

### Checkout session not redirecting

- Ensure `STRIPE_SECRET_KEY` is set correctly
- Check Rails logs for Stripe API errors

### Subscription not updating after checkout

- Verify webhooks are being received (check Stripe Dashboard > Developers > Webhooks > Events)
- Check Rails logs for any errors in the webhook handler
