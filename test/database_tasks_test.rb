# frozen_string_literal: true

require_relative 'test_helper'
require 'rake'
require_relative '../lib/tasks/db'

class DatabaseTasksTest < DatabaseTest
  def test_database_selection_is_isolated
    with_env('PGDATABASE' => 'api_rails_pg_development', 'DATABASE_URL' => 'postgres://localhost/other') do
      %w[development test production].each do |env|
        with_env('RACK_ENV' => env) do
          assert_equal "api_sinatra_pg_#{env}", Recruitment::Database.options[:database]
        end
      end
    end
    with_env('RACK_ENV' => 'other') { assert_raises(ArgumentError) { Recruitment::Database.options } }
  end

  def test_seed_registry_and_idempotence
    assert_equal 5, TEST_DB[:schema_seeds].count
    company = Recruitment::Company.create(name: 'Keep this', location: 'Here')
    Recruitment::Seeds.apply(TEST_DB)
    assert_equal 5, TEST_DB[:schema_seeds].count
    refute_nil Recruitment::Company[company.id]
  end

  def test_explicit_reseed_resets_data_and_sequences
    TEST_DB.transaction(savepoint: true, rollback: :always) do
      Recruitment::Company.create(name: 'Temporary', location: 'Here')
      Recruitment::Seeds.apply(TEST_DB, reseed: true)
      assert_equal [4, 7, 9, 4], %i[companies jobs geeks applies].map { |table| TEST_DB[table].count }
      assert_equal [1, 2, 3, 4], TEST_DB[:companies].order(:id).select_map(:id)
      assert_equal 5, Recruitment::Company.create(name: 'After seeds', location: 'Here').id
      assert_equal 5, TEST_DB[:schema_seeds].count
    end
  end

  def test_migrations_can_roll_back_and_reapply
    TEST_DB.transaction(savepoint: true, rollback: :always) do
      directory = File.join(Recruitment::ROOT, 'db/migrations')
      Sequel::Migrator.run(TEST_DB, directory, target: 0)
      %i[companies jobs geeks applies].each { |table| refute TEST_DB.table_exists?(table) }
      Sequel::Migrator.run(TEST_DB, directory)
      assert_equal 4, TEST_DB[:schema_info].get(:version)
      %i[companies jobs geeks applies].each { |table| assert TEST_DB.table_exists?(table) }
    end
  end

  def test_required_rake_tasks_are_registered
    %w[create migrate rollback reset version seed check datasets].each do |name|
      assert Rake::Task.task_defined?("db:#{name}")
    end
  end

  def test_migration_rollback_invalidates_seeds_and_can_be_seeded_again
    TEST_DB.transaction(savepoint: true, rollback: :always) do
      Recruitment::Migrations.run(TEST_DB, target: 3)
      assert_equal 0, TEST_DB[:schema_seeds].count
      Recruitment::Migrations.run(TEST_DB)
      Recruitment::Seeds.apply(TEST_DB)
      assert_equal [4, 7, 9, 4], %i[companies jobs geeks applies].map { |table| TEST_DB[table].count }
    end
  end

  def test_production_sample_seeds_are_refused
    with_env('RACK_ENV' => 'production') do
      error = assert_raises(RuntimeError) { Recruitment::Seeds.apply(TEST_DB) }
      assert_includes error.message, 'only in development/test'
    end
  end

  def test_reset_requires_exact_database_confirmation
    with_env('CONFIRM_RESET' => nil) do
      _, error = capture_io do
        assert_raises(SystemExit) { Rake::Task['db:reset'].execute }
      end
      assert_includes error, 'CONFIRM_RESET=api_sinatra_pg_test'
    end
    assert_equal 4, Recruitment::Company.count
  end
end
