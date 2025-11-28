# Email Setup (Resend)

This template uses [Resend](https://resend.com) for transactional emails in production.

## Configuration

### 1. Get your API key

1. Sign up at [resend.com](https://resend.com)
2. Go to **API Keys** in your dashboard
3. Create a new API key
4. Copy the key (starts with `re_`)

### 2. Add to environment

```bash
# .env or production environment
RESEND_API_KEY=re_your_api_key_here
```

### 3. Verify your domain

1. In Resend dashboard, go to **Domains**
2. Add your domain and follow DNS verification steps
3. Update `config/initializers/devise.rb` and `app/mailers/application_mailer.rb` with your verified sender email

## Environment behavior

| Environment | Delivery method | Notes |
|------------|-----------------|-------|
| Development | `letter_opener` | Opens emails in browser |
| Test | `test` | Emails stored in `ActionMailer::Base.deliveries` |
| Production | `resend` | Sends via Resend API |

## Testing emails locally

In development, emails open in your browser automatically via `letter_opener`.

To test with Resend in development, temporarily change `config/environments/development.rb`:

```ruby
config.action_mailer.delivery_method = :resend
```

## Troubleshooting

- **401 Unauthorized**: Check your `RESEND_API_KEY` is set correctly
- **Emails not sending**: Verify your domain is verified in Resend dashboard
- **From address rejected**: Ensure sender email uses your verified domain
