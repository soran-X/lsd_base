require 'spec_helper'

# SimpleCov must be started before loading Rails
require 'simplecov'
SimpleCov.start 'rails' do
  add_filter '/spec/'
  add_filter '/config/'
  add_filter '/vendor/'
  add_group 'Models',      'app/models'
  add_group 'Controllers', 'app/controllers'
  add_group 'Helpers',     'app/helpers'
end

ENV['RAILS_ENV'] = 'test'
# Unset DATABASE_URL so the test environment url: in database.yml takes effect
# (DATABASE_URL points to the dev DB in Docker; test env uses TEST_DATABASE_URL fallback)
ENV.delete('DATABASE_URL')
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?
require 'rspec/rails'
require 'capybara/rspec'
require 'shoulda/matchers'

# Load all support files
Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.fixture_paths = [ Rails.root.join('spec/fixtures') ]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include RequestHelpers, type: :request
  config.include SystemHelpers,  type: :system

  # Capybara system test config
  config.before(:each, type: :system) do
    driven_by :rack_test
  end

  config.before(:each, type: :system, js: true) do
    driven_by :selenium_headless
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
