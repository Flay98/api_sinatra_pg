# frozen_string_literal: true

require_relative '../config/database'
Sequel.extension :seed

module Recruitment
  module Seeds
    module_function

    def connection
      @connection || raise('Seed connection has not been set')
    end

    def apply(db, reseed: false)
      raise 'Sample seeds are available only in development/test' if Database.environment == 'production'
      Database.assert_project_database!(db)

      @connection = db
      Sequel::Seed.setup(Database.environment.to_sym)
      db.transaction do
        # Serialize concurrent seed runs; all files and their registry commit together.
        db.run('SELECT pg_advisory_xact_lock(4567001)')
        if reseed && db.table_exists?(:schema_seeds)
          db[:schema_seeds].delete
        end
        Sequel::Seeder.apply(db, File.join(ROOT, 'seeds'))
      end
    ensure
      @connection = nil
    end
  end
end
