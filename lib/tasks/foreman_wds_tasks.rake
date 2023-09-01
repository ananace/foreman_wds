# frozen_string_literal: true

require 'rake/testtask'

# Tests
namespace :test do
  desc "Test ForemanWDS"
  Rake::TestTask.new(:foreman_wds) do |t|
    test_dir = File.join(File.dirname(File.dirname(__dir__)), 'test')
    t.libs << ['test', test_dir]
    t.pattern = "#{test_dir}/**/*_test.rb"
    t.verbose = true
    t.warning = false
  end

  namespace :foreman_wds do
    task :coverage do
      ENV['COVERAGE'] = '1'

      Rake::Task['test:foreman_wds'].invoke
    end
  end
end

namespace :foreman_wds do
  task rubocop: :environment do
    begin
      require 'rubocop/rake_task'
      RuboCop::RakeTask.new(:rubocop_foreman_wds) do |task|
        task.patterns = ["#{ForemanWDS::Engine.root}/app/**/*.rb",
                         "#{ForemanWDS::Engine.root}/lib/**/*.rb"]
      end
    rescue StandardError
      puts 'Rubocop not loaded.'
    end

    Rake::Task['rubocop_foreman_wds'].invoke
  end
end

Rake::Task[:test].enhance ['test:foreman_wds']
# Rake::Task[:coverage].enhance ["test:foreman_liudesk_cmdb:coverage"]
