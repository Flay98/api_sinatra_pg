# frozen_string_literal: true

require_relative '../config/database'
require 'time'

module Recruitment
  Model = Sequel::Model(Database.connection)
  Model.plugin :validation_helpers
  Model.plugin :timestamps, update_on_create: true
  Model.plugin :defaults_setter

  module ModelMethods
    def to_api
      values.select { |key, _| self.class::API_FIELDS.include?(key) }
    end

    def to_detail
      values.transform_values { |value| value.respond_to?(:iso8601) ? value.iso8601 : value }
    end

    def validate_reference(field, klass)
      validates_integer field
      errors.add(field, 'does not exist') if self[field] && !klass[self[field]]
    end
  end

  module TextSearch
    def containing(column, value)
      return self if value.nil? || value.empty?

      # Treat user text literally, including SQL LIKE wildcards and backslashes.
      escaped = value.gsub(/[\\%_]/) { |char| "\\#{char}" }
      where(Sequel.ilike(column, "%#{escaped}%"))
    end
  end
  Model.dataset_module(TextSearch)
end

%w[company job geek apply].each { |file| require_relative file }
