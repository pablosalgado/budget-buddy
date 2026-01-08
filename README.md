# Budget Buddy

A YNAB (You Need A Budget) clone built with Ruby on Rails for learning and fun.

## About

This is a bare-bones project in early development. It's designed to replicate basic YNAB functionality as a learning exercise.

## Table of Contents

- [Tech Stack](#tech-stack)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
  - [Quick Setup (Recommended)](#quick-setup-recommended)
  - [Manual Setup](#manual-setup)
- [Testing](#testing)
  - [Running Tests](#running-tests)
  - [Useful Options](#useful-options)
- [Development](#development)
  - [Development Guidelines](#development-guidelines)
  - [Environment Variables](#environment-variables)
  - [Console](#console)
  - [Git Workflow](#git-workflow)
  - [Code Quality](#code-quality)
- [API Development](#api-development)
  - [Quick Start](#quick-start)
  - [Creating New API Endpoints](#creating-new-api-endpoints)
- [Security](#security)
- [Error Tracking](#error-tracking)
- [CI/CD](#cicd)
  - [GitHub Actions](#github-actions)
  - [Local CI](#local-ci)
- [Docker](#docker)
- [Deployment](#deployment)
- [Project Status](#project-status)
- [License](#license)

## Tech Stack

- **Ruby**: 3.x (check `.ruby-version` if present, or use latest stable)
- **Rails**: 8.1.1
- **Database**: PostgreSQL with multiple schemas (app, cache, queue, cable)
- **Asset Pipeline**: Propshaft (modern replacement for Sprockets)
- **JavaScript**: Importmap, Stimulus, Turbo (Hotwire stack)
- **Web Server**: Puma
- **Testing**: RSpec with FactoryBot, Shoulda Matchers, and Faker
- **Quality Tools**: RuboCop, Brakeman, bundler-audit
- **Deployment**: Kamal-ready with Docker support
- **API**: RESTful JSON API (versioned at `/api/v1`)

## Architecture

This project follows the **Majestic Monolith** approach:
- Single Rails application that scales through simplicity and convention
- Traditional Rails MVC for web interfaces
- RESTful JSON API support available at `/api/v1` (optional)
- Comprehensive test coverage for all layers

## Prerequisites

Before you begin, ensure you have the following installed:

- Ruby 3.x (recommended: use `rbenv` or `rvm`)
- PostgreSQL (via Homebrew on macOS: `brew install postgresql@15`)
- Bundler (`gem install bundler`)

## Getting Started

### Clone the repository

```bash
git clone <repository-url>
cd budget-buddy
```

### Quick Setup (Recommended)

The project includes an automated setup script:

```bash
bin/setup
```

This will:
- Install Ruby dependencies
- Create and set up the database
- Prepare all database schemas (main, cache, queue, cable)
- Remove old logs and temp files
- Start the development server

Visit [http://localhost:3000](http://localhost:3000) to view the application.

### Manual Setup

If you prefer to set up manually:

### 2. Install dependencies

```bash
bundle install
```

### 3. Set up environment variables

Copy the example environment file and configure your local values:

```bash
cp .env.example .env
```

Edit `.env` and fill in any required values. For local development, the defaults should work.

**Important**: Never commit `.env` to git - it's already in `.gitignore`.

### 4. Database setup

Make sure PostgreSQL is running:

```bash
# On macOS with Homebrew
brew services start postgresql@15
### 4. Database setup

Create and set up the database:

```bash
bin/rails db:create
bin/rails db:migrate
bin/rails db:seed
```

### 5. Start the development server

```bash
bin/dev
```

Or if you prefer to run Puma directly:

```bash
bin/rails server
```

Visit [http://localhost:3000](http://localhost:3000) to view the application.

## Testing

This project uses **RSpec** for testing with FactoryBot, Shoulda Matchers, and Faker.

### Running Tests

```bash
# Run all tests
bin/rspec

# Run a specific test file
bin/rspec spec/models/user_spec.rb

# Run a specific test by line number
bin/rspec spec/models/user_spec.rb:42

# Run tests matching a pattern
bin/rspec spec/models/
bin/rspec spec/requests/api/

# Run tests with a specific tag
bin/rspec --tag focus
bin/rspec --tag ~slow  # Exclude slow tests

# Run only failed tests from previous run
bin/rspec --only-failures

# Run tests with detailed output
bin/rspec --format documentation

# Run tests and show 10 slowest examples
bin/rspec --profile 10
```

### Useful Options

```bash
# Run tests in random order (detect order dependencies)
bin/rspec --order random

# Run tests with a specific seed (for reproducibility)
bin/rspec --seed 12345

# Run tests and stop on first failure
bin/rspec --fail-fast

# Run tests with coverage report (if SimpleCov is configured)
COVERAGE=true bin/rspec
```

> **For comprehensive testing patterns and best practices**, see [RSpec Instructions](/.github/instructions/rspec.instructions.md)

## Development

### Development Guidelines

Follow the established patterns documented in the instruction files:
- [Rails Instructions](/.github/instructions/rails.instructions.md) - MVC patterns and conventions
- [API Instructions](/.github/instructions/api.instructions.md) - RESTful API development
- [Ruby Instructions](/.github/instructions/ruby.instructions.md) - SOLID principles and clean code
- [RSpec Instructions](/.github/instructions/rspec.instructions.md) - Testing patterns

### Environment Variables

This project uses environment variables for configuration and secrets.

**Setup**:
```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your local values
nano .env  # or use your preferred editor
```

**Usage in code**:
```ruby
# Access environment variables
ENV['DATABASE_PASSWORD']
ENV.fetch('STRIPE_SECRET_KEY')  # Raises error if not set

# Rails encrypted credentials (alternative)
Rails.application.credentials.stripe_secret_key
```

**Important**:
- ❌ Never commit `.env` to git (already in `.gitignore`)
- ❌ Never hardcode secrets in your code
- ✅ Use ENV vars for all sensitive data
- ✅ Update `.env.example` when adding new variables

**Available variables**: See `.env.example` for a complete list

**Sentry Error Tracking**:
To enable error tracking, sign up at [sentry.io](https://sentry.io) (free tier), create a project, and add the DSN to your `.env`:
```bash
SENTRY_DSN=https://your-key@sentry.io/your-project-id
```

### Console

```bash
bin/rails console
```

### Git Workflow

**Branches**: `<type>/<ticket-id>-<description>` (e.g., `feat/123-add-budget-api`, `fix/456-validation-error`)

**Commits**: Follow [Conventional Commits](/.github/git-commit-instructions.md) specification

**Types**: `feat`, `fix`, `docs`, `style`, `refactor`, `perf`, `test`, `chore`, `ci`, `build`

### Code Quality

Run all quality checks:

```bash
bin/ci  # Runs tests with coverage, RuboCop, Brakeman, and bundler-audit
```

Individual checks:

```bash
# Tests
bundle exec rspec                    # Tests only
COVERAGE=true bundle exec rspec      # Tests with coverage report

# Code style
bundle exec rubocop                  # Check style
bundle exec rubocop -a               # Auto-fix violations

# Security
bundle exec brakeman -q              # Security analysis
bundle exec bundler-audit check      # Dependency vulnerabilities
```

**Test Coverage**: Minimum 85% total coverage, 75% per file. View detailed reports at `coverage/index.html` after running tests with `COVERAGE=true`.

For comprehensive coverage guidelines, see [Test Coverage Instructions](/.github/instructions/test-coverage.instructions.md).

## API Development

This project includes **RESTful JSON API support** alongside traditional Rails views.

### Quick Start

APIs are versioned at `/api/v1/`. A health check endpoint is available to verify the API is running:

```bash
# Start the server
bin/rails server

# Test the health check endpoint
curl http://localhost:3000/api/v1/health
```

Expected response:
```json
{
  "status": "healthy",
  "timestamp": "2026-01-07T12:00:00Z",
  "version": "1.0.0",
  "environment": "development",
  "checks": {
    "database": true,
    "cache": true
  }
}
```

### Creating New API Endpoints

> **📘 For complete API patterns and templates**, see [API Instructions](/.github/instructions/api.instructions.md)

The API Instructions file contains everything needed to build RESTful APIs:
- Controller templates (Base + Resource with all CRUD actions)
- Routing patterns (standard + custom routes)
- HTTP status codes and response formats
- Authentication (JWT)
- Pagination, filtering, sorting
- Serializers
- Error handling
- Testing patterns

**Reference Files:**
- Health Check Controller: `app/controllers/api/v1/health_controller.rb`
- Health Check Specs: `spec/requests/api/v1/health_spec.rb`
- Base Controller: `app/controllers/api/v1/base_controller.rb`

## Security

This project implements comprehensive security measures to protect against vulnerabilities.

### Automated Security Scanning

**Tools in use:**
- **Brakeman** - Static code analysis for Rails security vulnerabilities
- **bundler-audit** - Checks gems for known CVEs
- **Dependabot** - Automated dependency updates every Monday
- **RuboCop Security** - Enforces security best practices
- **TruffleHog** - Scans for accidentally committed secrets

**When they run:**
- Every pull request (via CI)
- Every push to main
- Weekly scheduled scans (Mondays at 9 AM)

### Security Workflows

```bash
# Run security scans locally
bin/brakeman --quiet           # Code vulnerabilities
bin/bundler-audit check        # Dependency vulnerabilities
bundle exec rubocop --only Security  # Security cops
```

### Reporting Vulnerabilities

Found a security issue? Please see [SECURITY.md](SECURITY.md) for our responsible disclosure policy.

**Do NOT create public issues for security vulnerabilities.**

### Security Configuration

- **Brakeman**: `config/brakeman.yml`
- **Bundler Audit**: `config/bundler-audit.yml`
- **Dependabot**: `.github/dependabot.yml`
- **Security Policy**: [SECURITY.md](SECURITY.md)

## Error Tracking

This project uses **Sentry** for automatic error capture and monitoring.

### Features

- 🐛 Automatic exception capture
- 📊 Error grouping and trends
- 🔔 Real-time alerts
- 📍 Stack traces with context
- 👤 User impact tracking
- 📈 Performance monitoring

### Setup

1. **Sign up** at [sentry.io](https://sentry.io) (free tier: 5,000 events/month)
2. **Create a project** (select Ruby/Rails)
3. **Get your DSN** from project settings
4. **Add to .env**:
   ```bash
   SENTRY_DSN=https://your-key@sentry.io/your-project-id
   ```

### Configuration

**Enabled environments**: Development, production, and staging (test disabled by default)

**To disable in development** (if you prefer):
```ruby
# config/initializers/sentry.rb
config.enabled_environments = %w[production staging]
```

### Testing

Once you've added your `SENTRY_DSN` to `.env`:

```bash
# Test with rake task
bin/rails sentry:test

# Or in Rails console
bin/rails console
> Sentry.capture_message("Test error from console")
> raise "Test error - check Sentry dashboard"
```

Check your Sentry dashboard to see the captured events.

### What Gets Captured

- All uncaught exceptions
- Stack traces with file/line numbers
- Request data (URL, method, params)
- User context (when authenticated)
- Server environment
- Breadcrumbs (events leading to error)

### Sensitive Data

Automatically filtered:
- Passwords
- Tokens
- Authorization headers
- Any field named `secret`

Configuration: `config/initializers/sentry.rb`

## CI/CD

### GitHub Actions

The project includes a comprehensive CI pipeline (`.github/workflows/ci.yml`) that runs automatically on:
- Pull requests
- Pushes to the `main` branch

The pipeline includes:

1. **Tests**: Runs RSpec test suite with PostgreSQL
2. **Security Scans**:
   - Brakeman (static security analysis)
   - bundler-audit (gem vulnerability checking)
   - importmap audit (JavaScript dependency scanning)
3. **Linting**: RuboCop style enforcement

### Local CI

Run the complete CI suite locally before pushing:

```bash
bin/ci
```

This runs the same checks as the GitHub Actions pipeline and helps catch issues early.

## Docker

This project includes Docker support:

```bash
docker build -t budget-buddy .
docker run -p 3000:3000 budget-buddy
```

## Deployment

The project is configured for deployment with Kamal. See `config/deploy.yml` for configuration.

## Project Status

🚧 **Early Development** - This is a learning project and currently has minimal functionality implemented.

## License

This project is for educational purposes.
