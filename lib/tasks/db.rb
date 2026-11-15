# frozen_string_literal: true

require_relative '../../config/database'
require_relative '../seeds'
require_relative '../migrations'

namespace :db do
  task :environment do
    Recruitment::Database.assert_project_database!(Recruitment::Database.connection)
  end

  desc 'Create only the three databases belonging to this project'
  task :create do
    config = Recruitment::Database.options.merge(database: 'postgres', max_connections: 1)
    Sequel.connect(config) do |admin|
      Recruitment::Database::DATABASES.each_value do |name|
        if admin[:pg_database].where(datname: name).count.positive?
          puts "Exists: #{name}"
        else
          admin.run("CREATE DATABASE #{admin.literal(Sequel.identifier(name))}")
          puts "Created: #{name}"
        end
      end
    end
  end

  desc 'Check PostgreSQL connection without showing credentials'
  task check: :environment do
    db = Recruitment::Database.connection
    puts "Connected: #{db.get(Sequel.lit('CURRENT_USER'))}@#{Recruitment::Database.name}"
    puts db.get(Sequel.function(:version))
  end

  desc 'Show current migration version'
  task version: :environment do
    db = Recruitment::Database.connection
    version = db.table_exists?(:schema_info) ? db[:schema_info].get(:version) : 0
    puts "#{Recruitment::Database.name}: schema version #{version}"
  end

  desc 'Migrate to latest version or db:migrate[version]'
  task :migrate, [:version] => :environment do |_, args|
    opts = args[:version] ? { target: Integer(args[:version], 10) } : {}
    Recruitment::Migrations.run(Recruitment::Database.connection, **opts)
    Rake::Task['db:version'].execute
  end

  desc 'Roll back one migration, or to db:rollback[target] (0 = all)'
  task :rollback, [:target] => :environment do |_, args|
    db = Recruitment::Database.connection
    current = db.table_exists?(:schema_info) ? db[:schema_info].get(:version) : 0
    target = args[:target] ? Integer(args[:target], 10) : [current - 1, 0].max
    Recruitment::Migrations.run(db, target: target)
    Rake::Task['db:version'].execute
  end

  desc 'DELETE project data and rebuild schema; requires CONFIRM_RESET=database_name'
  task reset: :environment do
    db = Recruitment::Database.connection
    abort "Set CONFIRM_RESET=#{Recruitment::Database.name} to reset this database" unless ENV['CONFIRM_RESET'] == Recruitment::Database.name
    db.transaction do
      Recruitment::Migrations.run(db, target: 0)
      db.drop_table?(:schema_seeds)
      Recruitment::Migrations.run(db)
    end
    Rake::Task['db:version'].execute
  end

  desc 'Apply pending Sequel seeds (development/test); repeat with RESEED=1'
  task seed: :environment do
    Recruitment::Seeds.apply(Recruitment::Database.connection, reseed: ENV['RESEED'] == '1')
    puts "#{Recruitment::Database.name}: seeds applied"
  end

  desc 'Show the dataset examples from part 3'
  task datasets: :environment do
    dataset = Recruitment::Database.connection[:companies]
    puts dataset.select(:id, :name).order(:name).where { id < 3 }.all.inspect
    puts "companies: #{dataset.count}, jobs: #{Recruitment::Database.connection[:jobs].count}"
  end
end
