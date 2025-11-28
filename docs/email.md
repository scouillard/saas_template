# Email Setup with Resend

This template uses [Resend](https://resend.com) for transactional email delivery in production.

## Configuration

### 1. Get your API key

1. Sign up at [resend.com](https://resend.com)
2. Navigate to API Keys in the dashboard
3. Create a new API key

### 2. Verify your domain

1. Go to Domains in the Resend dashboard
2. Add your domain and follow the DNS verification steps
3. Update `ApplicationMailer` with your verified sender address:

```ruby
# app/mailers/application_mailer.rb
class ApplicationMailer < ActionMailer::Base
  default from: "noreply@yourdomain.com"
  layout "mailer"
end
```

### 3. Set environment variables

```bash
RESEND_API_KEY=re_your_api_key_here
APP_HOST=yourdomain.com
```

## Development

In development, emails are opened in the browser using the `letter_opener` gem. No Resend configuration is needed locally.

## Testing

In test environment, emails are not delivered. Use `ActionMailer::Base.deliveries` to inspect sent emails in tests.
