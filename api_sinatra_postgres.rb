# frozen_string_literal: true

require_relative 'config/environment'
require 'sinatra/base'
require 'sinatra/namespace'
require 'json'
require_relative 'models/init'
require_relative 'helpers/api_helpers'
require_relative 'controllers/resources_controller'

module Recruitment
  class App < Sinatra::Base
    register Sinatra::Namespace
    helpers ApiHelpers

    set :root, ROOT
    set :port, Integer(ENV.fetch('PORT', '4567'))
    set :bind, '127.0.0.1'
    set :server, :puma
    set :show_exceptions, false
    set :raise_errors, false
    set :dump_errors, false
    set :static, false

    before { content_type :json, charset: 'utf-8' }

    register ResourcesController

    options '/api/v1/*' do
      headers 'Allow' => 'GET, HEAD, POST, PUT, PATCH, DELETE, OPTIONS'
      json_response(methods: %w[GET HEAD POST PUT PATCH DELETE OPTIONS])
    end

    error Sequel::ValidationFailed do
      exception = env['sinatra.error']
      api_error(422, 'Validation failed', errors: exception.model.errors)
    end

    error Sequel::ForeignKeyConstraintViolation do
      api_error(409, 'Operation conflicts with related records')
    end

    error Sequel::UniqueConstraintViolation do
      api_error(409, 'Record already exists')
    end

    error Sequel::NotNullConstraintViolation, Sequel::CheckConstraintViolation, Sequel::InvalidValue do
      api_error(422, 'Invalid attributes')
    end

    error Sequel::DatabaseError do
      exception = env['sinatra.error']
      if exception.wrapped_exception.is_a?(PG::RestrictViolation)
        api_error(409, 'Operation conflicts with related records')
      else
        warn "Database request failed: #{exception.wrapped_exception.class}"
        json_response({ message: 'Internal Server Error', status: 500 }, 500)
      end
    end

    error Rack::QueryParser::ParameterTypeError, Rack::QueryParser::InvalidParameterError do
      api_error(400, 'Malformed parameters')
    end

    not_found do
      # Keep explicit 404 response bodies produced by find_record.
      if response.body.empty?
        json_response({ message: 'Route Not Found', status: 404, path: request.path_info,
                        splat: [request.path_info.sub(%r{\A/}, '')] }, 404)
      else
        response.body
      end
    end

    error do
      warn "Request failed: #{env['sinatra.error'].class}"
      json_response({ message: 'Internal Server Error', status: 500 }, 500)
    end
  end
end

Dir[File.join(Recruitment::ROOT, 'routes/*.rb')].sort.each { |file| require file }

Recruitment::App.run! if $PROGRAM_NAME == __FILE__
