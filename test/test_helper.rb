# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
require_relative '../config/database'
require_relative '../lib/seeds'
require 'minitest/autorun'
require 'rack/test'
require 'json'

TEST_DB = Recruitment::Database.connection
Recruitment::Database.assert_project_database!(TEST_DB)
Sequel.extension :migration
Sequel::Migrator.run(TEST_DB, File.join(Recruitment::ROOT, 'db/migrations'))
Recruitment::Seeds.apply(TEST_DB)
require_relative '../api_sinatra_postgres'

class DatabaseTest < Minitest::Test
  def run
    TEST_DB.transaction(rollback: :always, auto_savepoint: true) { super }
  end

  def with_env(values)
    old = values.to_h { |key, _| [key, ENV[key]] }
    values.each { |key, value| ENV[key] = value }
    yield
  ensure
    old.each { |key, value| ENV[key] = value }
  end
end

class ApiTest < DatabaseTest
  include Rack::Test::Methods

  def app
    Recruitment::App
  end

  def setup
    header 'Host', 'localhost'
  end

  def body
    JSON.parse(last_response.body)
  end

  def send_json(method, path, attributes)
    public_send(method, path, JSON.generate(attributes), 'CONTENT_TYPE' => 'application/json')
  end

  def assert_json_status(expected)
    assert_equal expected, last_response.status, last_response.body
    assert_match %r{application/json}, last_response.content_type
    body
  end
end
