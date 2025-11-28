# Stripe Setup Guide

This guide covers setting up Stripe Checkout for subscription billing.

## 1. Get API Keys

1. Go to [Stripe Dashboard](https://dashboard.stripe.com)
2. Sign up or log in
3. Navigate to **Developers > API keys**
4. Copy your keys:
   - **Publishable key** (starts with `pk_test_` or `pk_live_`)
   - **Secret key** (starts with `sk_test_` or `sk_live_`)

Add to your `.env` file:
```
STRIPE_PUBLISHABLE_KEY=pk_test_your_key
STRIPE_SECRET_KEY=sk_test_your_key
```

**Note:** Use test keys (`pk_test_`, `sk_test_`) for development. Switch to live keys for production.

## 2. Create Products and Prices

1. Go to **Products** in the Stripe Dashboard
2. Click **Add product**
3. Fill in product details:
   - Name: "Pro Plan" (or your plan name)
   - Description: optional
4. Add pricing:
   - Click **Add price**
   - **Monthly**: Set price (e.g., $19/month), select "Recurring", billing period "Monthly"
   - **Yearly**: Add another price (e.g., $180/year), select "Recurring", billing period "Yearly"
5. Save the product
6. Copy the **Price IDs** (start with `price_`) for each price

Add to your `.env` file:
```
STRIPE_PRICE_MONTHLY=price_your_monthly_price_id
STRIPE_PRICE_YEARLY=price_your_yearly_price_id
```

## 3. Set Up Webhooks

### Production Webhook

1. Go to **Developers > Webhooks**
2. Click **Add endpoint**
3. Enter your endpoint URL: `https://yourdomain.com/stripe/webhook`
4. Select events to listen for:
   - `checkout.session.completed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
5. Click **Add endpoint**
6. Copy the **Signing secret** (starts with `whsec_`)

Add to your `.env` file:
```
STRIPE_WEBHOOK_SECRET=whsec_your_signing_secret
```

### Local Development with Stripe CLI

For local testing, use the Stripe CLI to forward webhook events:

1. **Install Stripe CLI**:
   ```bash
   # macOS
   brew install stripe/stripe-cli/stripe

   # Linux (Debian/Ubuntu)
   curl -s https://packages.stripe.dev/api/security/keypair/stripe-cli-gpg/public | gpg --dearmor | sudo tee /usr/share/keyrings/stripe.gpg
   echo "deb [signed-by=/usr/share/keyrings/stripe.gpg] https://packages.stripe.dev/stripe-cli-debian-local stable main" | sudo tee -a /etc/apt/sources.list.d/stripe.list
   sudo apt update && sudo apt install stripe

   # Windows (via scoop)
   scoop install stripe
   ```

2. **Log in to Stripe**:
   ```bash
   stripe login
   ```

3. **Forward webhooks to your local server**:
   ```bash
   stripe listen --forward-to localhost:3000/stripe/webhook
   ```

4. The CLI will output a webhook signing secret like:
   ```
   Ready! Your webhook signing secret is whsec_xxxxx
   ```

5. Add this to your `.env`:
   ```
   STRIPE_WEBHOOK_SECRET=whsec_xxxxx
   ```

**Keep the `stripe listen` command running** while testing webhooks locally.

## 4. Test the Integration

1. Start your Rails server: `bin/dev`
2. In another terminal, run: `stripe listen --forward-to localhost:3000/stripe/webhook`
3. Go to the Plan & Billing page in your app
4. Click "Subscribe" on a plan
5. Use Stripe test card: `4242 4242 4242 4242`
   - Expiry: Any future date
   - CVC: Any 3 digits
   - ZIP: Any 5 digits
6. Complete the checkout
7. Verify the subscription is active in your app

### Test Card Numbers

| Card Number | Behavior |
|-------------|----------|
| `4242 4242 4242 4242` | Succeeds |
| `4000 0000 0000 3220` | Requires 3D Secure |
| `4000 0000 0000 9995` | Declines (insufficient funds) |

See [Stripe testing docs](https://stripe.com/docs/testing) for more test cards.

## 5. Go Live

When ready for production:

1. Replace test keys with live keys in your production environment
2. Create products/prices in live mode (or copy from test mode)
3. Update webhook endpoint to your production URL
4. Test with a real card (you can refund immediately)

## Troubleshooting

### Webhook signature verification fails
- Ensure `STRIPE_WEBHOOK_SECRET` matches the signing secret from Stripe
- For local development, use the secret from `stripe listen` output
- For production, use the secret from the webhook endpoint settings

### Checkout session fails
- Verify `STRIPE_SECRET_KEY` is correct
- Check that price IDs exist and are active in Stripe
- Ensure the price is for the correct mode (test vs live)

### Subscription not updating after checkout
- Check webhook events in Stripe Dashboard > Developers > Webhooks
- Look for failed webhook deliveries
- Check Rails logs for webhook processing errors
