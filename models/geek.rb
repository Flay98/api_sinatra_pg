# frozen_string_literal: true

module Recruitment
  class Geek < Model
    include ModelMethods
    API_FIELDS = %i[id name stack resume].freeze
    WRITABLE_FIELDS = { name: :string, stack: :string, resume: :boolean }.freeze

    one_to_many :applies, class: 'Recruitment::Apply', key: :geek_id
    many_to_many :jobs, class: 'Recruitment::Job', join_table: :applies,
                       left_key: :geek_id, right_key: :job_id

    def validate
      super
      validates_presence %i[name stack]
      validates_schema_types
      validates_includes [true, false], :resume
    end
  end
end
