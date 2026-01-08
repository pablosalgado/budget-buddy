# frozen_string_literal: true

namespace :sentry do
  desc "Test Sentry error tracking integration"
  task test: :environment do
    if ENV["SENTRY_DSN"].blank?
      puts "❌ SENTRY_DSN not configured"
      puts "   Add your Sentry DSN to .env:"
      puts "   SENTRY_DSN=https://your-key@sentry.io/your-project-id"
      puts ""
      puts "   Get your DSN from: https://sentry.io/settings/projects/"
      exit 1
    end

    puts "🔍 Testing Sentry integration..."
    puts ""

    # Test 1: Simple message
    puts "1. Sending test message..."
    Sentry.capture_message("Test message from rake task")
    puts "   ✅ Message sent"
    puts ""

    # Test 2: Exception with context
    puts "2. Sending test exception with context..."
    Sentry.with_scope do |scope|
      scope.set_context(:test_info, {
        task: "sentry:test",
        timestamp: Time.current,
        ruby_version: RUBY_VERSION,
        rails_version: Rails.version
      })

      begin
        raise StandardError, "Test exception from rake task"
      rescue => e
        Sentry.capture_exception(e)
        puts "   ✅ Exception sent"
      end
    end
    puts ""

    # Test 3: User context
    puts "3. Sending error with user context..."
    Sentry.set_user(id: 999, email: "test@example.com", username: "Test User")
    Sentry.capture_message("Test error with user context")
    puts "   ✅ Error with user context sent"
    puts ""

    puts "✅ All tests complete!"
    puts ""
    puts "Check your Sentry dashboard:"
    puts "https://sentry.io/organizations/your-org/issues/"
    puts ""
    puts "You should see 3 new events:"
    puts "  • Test message from rake task"
    puts "  • Test exception from rake task (with context)"
    puts "  • Test error with user context"
  end
end
