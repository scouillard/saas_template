# Email Setup with Resend

This template uses [Resend](https://resend.com) for transactional email delivery in production.

## Configuration

### 1. Get your API key

1. Sign up at [resend.com](https://resend.com)
2. Go to API Keys and create a new key
3. Copy the key (starts with `re_`)

### 2. Add your domain

1. In Resend dashboard, go to Domains
2. Add your domain and follow DNS verification steps
3. Wait for domain verification (usually a few minutes)

### 3. Set environment variables

Add your API key to your production environment:

```bash
RESEND_API_KEY=re_your_api_key_here
```

### 4. Update sender addresses

Update the default sender in `app/mailers/application_mailer.rb`:

```ruby
default from: "noreply@yourdomain.com"
```

For Devise emails, update `config/initializers/devise.rb`:

```ruby
config.mailer_sender = "noreply@yourdomain.com"
```

## Development

In development, emails are opened in the browser via [letter_opener](https://github.com/ryanb/letter_opener). No Resend configuration needed.

## Testing

In test environment, emails use Rails' `:test` delivery method and are not sent. Access sent emails via `ActionMailer::Base.deliveries`.
