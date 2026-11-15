# frozen_string_literal: true

require 'bundler/setup'
require 'dotenv'

module Recruitment
  ROOT = File.expand_path('..', __dir__)
end

Dotenv.load(File.join(Recruitment::ROOT, '.env'))
ENV['RACK_ENV'] ||= 'development'
