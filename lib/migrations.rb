# frozen_string_literal: true

require_relative '../config/database'
Sequel.extension :migration

module Recruitment
  module Migrations
    module_function

    def run(db, target: nil)
      Database.assert_project_database!(db)
      current = db.table_exists?(:schema_info) ? db[:schema_info].get(:version) : 0
      options = target ? { target: target } : {}
      db.transaction do
        Sequel::Migrator.run(db, File.join(ROOT, 'db/migrations'), **options)
        # A rollback drops seeded tables: their old seed ledger is no longer valid.
        if target && target < current && db.table_exists?(:schema_seeds)
          db[:schema_seeds].delete
        end
      end
    end
  end
end
