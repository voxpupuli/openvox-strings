# frozen_string_literal: true

require 'bundler/gem_tasks'
require 'puppet-lint/tasks/puppet-lint'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.exclude_pattern = "spec/acceptance/**/*.rb"
end

namespace :spec do
  desc 'Run RSpec code examples with coverage collection'
  task :coverage do
      ENV['COVERAGE'] = 'yes'
      Rake::Task['spec'].execute
  end
end


RSpec::Core::RakeTask.new(:acceptance) do |t|
  t.pattern = "spec/unit/**/*.rb"
end

task :spec => :spec_clean
task :acceptance => :spec_prep

# Add our own tasks
require 'puppet-strings/tasks'

PuppetLint.configuration.send('disable_80chars')
PuppetLint.configuration.ignore_paths = %w(acceptance/**/*.pp spec/**/*.pp pkg/**/*.pp)

desc 'Validate Ruby source files and ERB templates.'
task :validate do
  Dir['spec/**/*.rb','lib/**/*.rb'].each do |ruby_file|
    sh "ruby -c #{ruby_file}" unless /spec\/fixtures/.match?(ruby_file)
  end
  Dir['lib/puppet-strings/yard/templates/**/*.erb'].each do |template|
    sh "erb -P -x -T '-' #{template} | ruby -c"
  end
end
