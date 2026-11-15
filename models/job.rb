# frozen_string_literal: true

module Recruitment
  class Job < Model
    include ModelMethods
    API_FIELDS = %i[id name company_id place].freeze
    WRITABLE_FIELDS = { name: :string, place: :string, company_id: :integer }.freeze

    many_to_one :company, class: 'Recruitment::Company', key: :company_id
    one_to_many :applies, class: 'Recruitment::Apply', key: :job_id
    many_to_many :geeks, class: 'Recruitment::Geek', join_table: :applies,
                        left_key: :job_id, right_key: :geek_id

    def validate
      super
      validates_presence %i[name place company_id]
      validates_schema_types
      validate_reference(:company_id, Company)
    end

    dataset_module do
      def by_name(value)
        containing(:name, value)
      end

      alias name by_name

      def place(value)
        containing(:place, value)
      end

      def company_jobs(company_id)
        where(company_id: company_id)
      end

      def by_company_name(value)
        where(company_id: Company.by_name(value).select(:id))
      end
    end
  end
end
