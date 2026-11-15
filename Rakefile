# frozen_string_literal: true

require_relative 'config/environment'
require 'rake/testtask'
require_relative 'lib/tasks/db'

Rake::TestTask.new(:test) do |task|
  task.libs << 'test'
  task.pattern = 'test/**/*_test.rb'
  task.warning = true
end

task default: :test
