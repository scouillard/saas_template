# SaaS Template

A Ruby on Rails 8.1 SaaS template with Ruby 3.2.0.

## Tech Stack

- **Framework**: Ruby on Rails 8.1
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS + DaisyUI
- **Database**: SQLite3
- **Background Jobs**: Solid Queue/Cache/Cable

## Getting Started

```bash
bin/setup    # Initial setup (idempotent, safe to re-run)
bin/dev      # Start dev server (web + CSS watcher)
```

## Testing

```bash
bundle exec rspec    # Run all specs
```

## Linting

```bash
bin/rubocop          # Ruby code style
bin/brakeman         # Security scanner
```

## Deployment

This project uses Kamal for deployment:

```bash
bin/kamal deploy     # Deploy new version
```
