# frozen_string_literal: true

module Recruitment
  class Company < Model
    include ModelMethods
    API_FIELDS = %i[id name location].freeze
    WRITABLE_FIELDS = { name: :string, location: :string }.freeze

    one_to_many :jobs, class: 'Recruitment::Job', key: :company_id

    def validate
      super
      validates_presence %i[name location]
      validates_schema_types
    end

    def self.by_name(name)
      dataset.containing(:name, name)
    end

    def self.company_jobs(name)
      Job.where(company_id: by_name(name).select(:id)).order(:id)
    end

    dataset_module do
      def by_location(location)
        containing(:location, location)
      end
    end
  end
end
