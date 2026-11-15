# frozen_string_literal: true

module Recruitment
  module ApiHelpers
    def json_response(value, status_code = 200)
      status status_code
      JSON.generate(value)
    end

    def collection_to_api(collection)
      json_response(collection.map(&:to_api))
    end

    def api_error(code, message, details = {})
      halt code, JSON.generate({ message: message, status: code }.merge(details))
    end

    def query_params
      # Rack 3 uses '&'; preserve the semicolon examples printed in part 4.
      @query_params ||= Rack::Utils.parse_nested_query(request.query_string.tr(';', '&'))
    end

    def text_filter(key)
      value = query_params[key.to_s]
      api_error(400, "#{key} must be a string") unless value.nil? || value.is_a?(String)
      value
    end

    def positive_id(value, key = :id)
      string = value.to_s
      api_error(400, "#{key} must be a positive integer") unless /\A[1-9]\d*\z/.match?(string)
      number = Integer(string, 10)
      api_error(400, "#{key} is out of range") if number > 2_147_483_647
      number
    end

    def boolean_value(value, key)
      return value if value == true || value == false
      return true if value == 'true'
      return false if value == 'false'

      api_error(422, "#{key} must be true or false")
    end

    def find_record(model, id)
      model[positive_id(id)] || api_error(404, 'Document Not Found', params_id: id)
    end

    def resource_attributes(model)
      request.body.rewind
      raw_body = request.body.read
      attributes = if raw_body.empty?
                     query_params
                   elsif request.media_type == 'application/json'
                     JSON.parse(raw_body)
                   elsif request.media_type == 'application/x-www-form-urlencoded'
                     Rack::Utils.parse_nested_query(raw_body)
                   else
                     api_error(415, 'Use application/json or application/x-www-form-urlencoded')
                   end
      api_error(400, 'Request body must be a JSON object') unless attributes.is_a?(Hash)
      fields = model::WRITABLE_FIELDS
      unknown = attributes.keys.map(&:to_s) - fields.keys.map(&:to_s)
      api_error(422, 'Unknown attributes', attributes: unknown) unless unknown.empty?
      attributes.to_h do |key, value|
        key = key.to_sym
        cast = case fields.fetch(key)
               when :string
                 api_error(422, "#{key} must be a string") unless value.is_a?(String)
                 value.strip
               when :integer then positive_id(value, key)
               when :boolean then boolean_value(value, key)
               end
        [key, cast]
      end
    rescue JSON::ParserError
      api_error(400, 'Malformed JSON')
    end

    def filtered_companies
      Company.by_name(text_filter(:name)).by_location(text_filter(:location)).order(:id)
    end

    def replacement_attributes(model, attributes)
      model::WRITABLE_FIELDS.to_h do |key, _|
        [key, attributes.fetch(key) { model.db_schema.fetch(key)[:ruby_default] }]
      end
    end

    def filtered_jobs
      jobs = Job.by_name(text_filter(:name)).place(text_filter(:place))
      jobs = jobs.by_company_name(text_filter(:company)) if query_params.key?('company')
      jobs = jobs.where(company_id: positive_id(query_params['company_id'], :company_id)) if query_params.key?('company_id')
      jobs.order(:id)
    end

    def filtered_geeks
      geeks = Geek.containing(:name, text_filter(:name)).containing(:stack, text_filter(:stack))
      geeks = geeks.where(resume: boolean_value(query_params['resume'], :resume)) if query_params.key?('resume')
      geeks.order(:id)
    end

    def filtered_applies
      applies = Apply.dataset
      %w[job_id geek_id].each do |key|
        applies = applies.where(key.to_sym => positive_id(query_params[key], key)) if query_params.key?(key)
      end
      %w[read invited].each do |key|
        applies = applies.where(key.to_sym => boolean_value(query_params[key], key)) if query_params.key?(key)
      end
      applies.order(:id)
    end
  end
end
