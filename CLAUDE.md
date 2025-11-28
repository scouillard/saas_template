# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Ruby on Rails 8.1 SaaS template using Ruby 3.2.0. The stack includes Hotwire (Turbo + Stimulus), Tailwind CSS, SQLite3 with multi-database support, Solid Queue for background jobs, Solid Cache, and Solid Cable for WebSockets.

## Common Commands

### Development
```bash
bin/setup              # Initial setup (idempotent, safe to re-run)
bin/dev                # Start dev server (web + CSS watcher)
bin/rails server       # Start Rails server only (port 3000)
```

### Testing
```bash
bin/rails test                    # Run all unit tests
bin/rails test:system             # Run browser/system tests
bin/rails test test/models/user_test.rb           # Run single test file
bin/rails test test/models/user_test.rb:10        # Run specific test line
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
