source "https://rubygems.org"

# Core
gem "rails", "~> 8.1.0"
gem "propshaft"
gem "sqlite3", ">= 2.1"
gem "puma", ">= 5.0"
gem "bootsnap", require: false
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Frontend
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "jbuilder"

# Solid Stack (database-backed adapters for cache, jobs, websockets)
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Authentication & Authorization
gem "devise"
gem "omniauth"
gem "omniauth-google-oauth2"
gem "omniauth-rails_csrf_protection"

# Payments
gem "stripe"

# Notifications
gem "noticed"

# Admin
gem "madmin"

# Pagination
gem "pagy"

# Internationalization
gem "rails-i18n"

# Email
gem "resend"

# Active Storage
gem "image_processing", "~> 1.2"

# Deployment
gem "kamal", require: false
gem "thruster", require: false

group :development, :test do
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Testing
  gem "rspec-rails"
  gem "factory_bot_rails"
  gem "faker"

  # Security & Linting
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
  gem "rubocop-rspec", require: false
end

group :development do
  gem "web-console"
  gem "letter_opener"
  gem "bullet"
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
  gem "shoulda-matchers"
end
