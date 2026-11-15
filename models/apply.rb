# frozen_string_literal: true

module Recruitment
  class Apply < Model
    include ModelMethods
    API_FIELDS = %i[id read invited job_id geek_id].freeze
    WRITABLE_FIELDS = { job_id: :integer, geek_id: :integer, read: :boolean, invited: :boolean }.freeze

    many_to_one :job, class: 'Recruitment::Job', key: :job_id
    many_to_one :geek, class: 'Recruitment::Geek', key: :geek_id

    def validate
      super
      validates_presence %i[job_id geek_id]
      validates_schema_types
      validates_includes [true, false], %i[read invited]
      validate_reference(:job_id, Job)
      validate_reference(:geek_id, Geek)
    end

    dataset_module do
      def read
        where(read: true)
      end

      def unread
        where(read: false)
      end
    end
  end
end
