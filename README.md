# SaaS Template

Ruby on Rails 8.1 SaaS template with Ruby 3.2.0.

## Stack

- **Framework**: Ruby on Rails 8.1
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS + DaisyUI
- **Database**: SQLite3
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **WebSockets**: Solid Cable

## Getting Started

```bash
bin/setup    # Initial setup (idempotent, safe to re-run)
bin/dev      # Start dev server (web + CSS watcher)
```

## Testing

```bash
bundle exec rspec                              # Run all specs
bundle exec rspec spec/models                  # Run model specs
bundle exec rspec spec/models/user_spec.rb    # Run single file
```

## Linting & Security

```bash
bin/rubocop        # Ruby code style
bin/brakeman       # Security vulnerability scanner
bin/bundler-audit  # Gem vulnerability audit
```

## CI

```bash
bin/ci  # Run full CI suite (setup, lint, security, tests)
```

## Deployment

Uses Kamal for deployment:

```bash
bin/kamal boot    # Initial deployment
bin/kamal deploy  # Deploy new version
```
