# frozen_string_literal: true

require "simplecov"
require "simplecov-console"

SimpleCov.start "rails" do
  # Minimum coverage threshold - adjusted to realistic levels
  minimum_coverage 85
  minimum_coverage_by_file 75

  # Output formatters
  formatter SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    SimpleCov::Formatter::Console
  ])

  # Coverage directory
  coverage_dir "coverage"

  # Files to exclude from coverage
  add_filter "/spec/"
  add_filter "/config/"
  add_filter "/db/schema.rb"
  add_filter "/db/seeds.rb"
  add_filter "/db/migrate/"
  add_filter "/vendor/"
  add_filter "/lib/tasks/"

  # Exclude base classes with no custom logic
  add_filter "app/controllers/application_controller.rb"
  add_filter "app/models/application_record.rb"
  add_filter "app/jobs/application_job.rb"
  add_filter "app/mailers/application_mailer.rb"
  add_filter "app/helpers/"

  # Group coverage by component
  add_group "Models", "app/models"
  add_group "Controllers", "app/controllers"
  add_group "Services", "app/services"
  add_group "Queries", "app/queries"
  add_group "Jobs", "app/jobs"
  add_group "Mailers", "app/mailers"
  add_group "Helpers", "app/helpers"

  # Track files with no coverage
  track_files "{app,lib}/**/*.rb"
end
