source "https://rubygems.org"

# Core Rails
# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 8.0.2", ">= 8.0.2.1"

# Web Server & Database
gem "puma", ">= 5.0"      # Use the Puma web server [https://github.com/puma/puma]
gem "pg", "~> 1.1"         # Use postgresql as the database for Active Record

# Assets & Frontend
gem "propshaft"            # The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "importmap-rails"      # Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "turbo-rails"          # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "stimulus-rails"       # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "tailwindcss-rails"    # Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]

# Background Jobs, Caching & Action Cable
gem "sidekiq", "~> 8.0"
gem "solid_cache"          # Database-backed adapter for Rails.cache
gem "solid_queue"          # Database-backed adapter for Active Job
gem "solid_cable"          # Database-backed adapter for Action Cable

# API & Authentication
gem "jbuilder"             # Build JSON APIs with ease [https://github.com/rails/jbuilder]
gem "bcrypt", "~> 3.1.7"   # Use Active Model has_secure_password [https://guides.rubyonrails.org/active_model_basics.html#securepassword]
gem "pundit", "~> 2.5"     # Object-oriented authorization

# Utilities
gem "friendly_id", "~> 5.5" # Create human-friendly URLs
gem "whenever", "~> 1.0"    # Schedule jobs with cron
gem "pagy", "~> 9.4"        # High-performance pagination
gem "discard", "~> 1.4"     # Soft deletes for Active Record
gem "rails-i18n"            # Default locale data

# Data, Analytics & Charts
gem "groupdate", "~> 6.7"   # Group temporal data easily
gem "chartkick", "~> 5.2"   # Create beautiful JavaScript charts
gem "highcharts", "~> 0.0.3" # Dependency for Chartkick

# File Processing
# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

# Deployment & Performance
gem "bootsnap", require: false  # Reduces boot times through caching; required in config/boot.rb
gem "kamal", require: false     # Deploy this application anywhere as a Docker container [https://kamal-deploy.org]
gem "thruster", require: false  # HTTP asset caching/compression for Puma [https://github.com/basecamp/thruster/]

# Platform-specific
gem "tzinfo-data", platforms: %i[ windows jruby ] # Windows does not include zoneinfo files

# Development & Test environments
group :development, :test do
  # Debugging & Code Analysis
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude" # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "brakeman", require: false                                      # Static analysis for security vulnerabilities [https://brakemanscanner.org/]
  gem "rubocop-rails-omakase", require: false                         # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
end

# Development environment
group :development do
  gem "web-console" # Use console on exceptions pages [https://github.com/rails/web-console]
end

# Testing Framework & Tools
group :development, :test do
  # Core Testing Framework
  gem "rspec-rails"
  gem "rails-controller-testing"

  # Testing Utilities
  gem "factory_bot_rails"
  gem "faker"
  gem "shoulda-matchers"
  gem "dotenv-rails"

  # Feature & Browser Testing
  gem "capybara"
  gem "selenium-webdriver"

  # Email Testing
  gem "letter_opener"
  gem "letter_opener_web"
end

# Test environment
group :test do
  gem "rspec-sidekiq" # Test Sidekiq workers
end