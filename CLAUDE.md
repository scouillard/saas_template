# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby on Rails 8.1 SaaS template with Ruby 3.2.0. Stack: Hotwire (Turbo + Stimulus), Tailwind CSS + DaisyUI, SQLite3, Solid Queue/Cache/Cable.

## Documentation

- **Design guidelines**: `docs/design.md` - Read before any UI work

## Common Commands

### Development
```bash
bin/setup              # Initial setup (idempotent, safe to re-run)
bin/dev                # Start dev server (web + CSS watcher)
bin/rails server       # Start Rails server only (port 3000)
```

### Testing (RSpec)
```bash
bundle exec rspec                              # Run all specs
bundle exec rspec spec/models                  # Run model specs
bundle exec rspec spec/models/user_spec.rb    # Run single file
bundle exec rspec spec/models/user_spec.rb:10 # Run specific line
```

### Linting & Security
```bash
bin/rubocop            # Ruby code style (Omakase Rails style)
bin/brakeman           # Security vulnerability scanner
bin/bundler-audit      # Gem vulnerability audit
bin/importmap audit    # JavaScript dependency audit
```

### CI Pipeline
```bash
bin/ci                 # Run full CI suite (setup, lint, security, tests)
```

### Deployment (Kamal)
```bash
bin/kamal boot         # Initial deployment
bin/kamal deploy       # Deploy new version
bin/kamal console      # Rails console in production
```

## Architecture

**Standard Rails MVC with Hotwire:**
- Controllers in `app/controllers/` handle HTTP requests
- Models in `app/models/` with concerns in `app/models/concerns/`
- Views in `app/views/` use ERB templates with Tailwind CSS
- Stimulus controllers in `app/javascript/controllers/`

**Multi-Database Configuration:**
- Primary database: SQLite3 (`storage/development.sqlite3`)
- Separate databases for cache, queue, and cable (Action Cable)
- Schema files: `db/cache_schema.rb`, `db/queue_schema.rb`, `db/cable_schema.rb`

**Background Jobs:**
- Solid Queue runs in-process with Puma by default
- Configuration: `config/queue.yml`
- Recurring jobs: `config/recurring.yml`

**Key Configuration Files:**
- `config/routes.rb` - URL routing
- `config/deploy.yml` - Kamal deployment
- `config/database.yml` - Database adapters
- `.rubocop.yml` - Code style (inherits from rubocop-rails-omakase)
