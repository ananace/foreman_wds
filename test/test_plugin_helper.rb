# frozen_string_literal: true

if ENV['COVERAGE']
  require 'simplecov'

  SimpleCov.start 'rails' do
    root File.dirname(__dir__)

    add_group 'Interactors', '/app/interactors'
    add_group 'Services', '/app/services'

    formatter SimpleCov::Formatter::SimpleFormatter if ENV['CI']
  end
end

# This calls the main test_helper in Foreman-core
require 'test_helper'

ActiveSupport::TestCase.file_fixture_path = File.join(__dir__, 'fixtures')

# Add plugin to FactoryBot's paths
FactoryBot.definition_file_paths << File.join(__dir__, 'factories')
FactoryBot.reload
