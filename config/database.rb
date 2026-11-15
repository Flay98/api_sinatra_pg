# frozen_string_literal: true

require_relative 'environment'
require 'sequel'
require 'pg'

module Recruitment
  module Database
    DATABASES = %w[development test production].to_h { |env| [env, "api_sinatra_pg_#{env}"] }.freeze

    module_function

    def environment
      ENV.fetch('RACK_ENV', 'development').tap do |env|
        raise ArgumentError, "Unknown RACK_ENV: #{env}" unless DATABASES.key?(env)
      end
    end

    def name
      DATABASES.fetch(environment)
    end

    def options
      {
        adapter: 'postgres', host: ENV.fetch('PGHOST', 'localhost'),
        port: Integer(ENV.fetch('PGPORT', '5433')), user: ENV.fetch('PGUSER', 'yanik_pryanik'),
        password: ENV['PGPASSWORD'], database: name,
        max_connections: Integer(ENV.fetch('DB_MAX_CONNECTIONS', '5')),
        connect_timeout: 5
      }
    end

    def connection
      @connection ||= Sequel.connect(options)
    end

    def assert_project_database!(db)
      actual = db.get(Sequel.function(:current_database))
      raise "Refusing to modify database #{actual}" unless actual == name
    end
  end
end

Sequel.default_timezone = :utc
