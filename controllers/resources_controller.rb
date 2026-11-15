# frozen_string_literal: true

module Recruitment
  module ResourcesController
    def self.registered(app)
      { companies: [Company, :filtered_companies], jobs: [Job, :filtered_jobs],
        geeks: [Geek, :filtered_geeks], applies: [Apply, :filtered_applies] }.each do |resource, (model, filter)|
        app.namespace '/api/v1' do
          get "/#{resource}" do
            collection_to_api(public_send(filter))
          end

          get "/#{resource}/:id" do
            json_response(find_record(model, params[:id]).to_detail)
          end

          post "/#{resource}" do
            record = model.create(resource_attributes(model))
            headers 'Location' => "/api/v1/#{resource}/#{record.id}"
            json_response(record.to_detail, 201)
          end

          %i[put patch].each do |verb|
            public_send(verb, "/#{resource}/:id") do
              record = find_record(model, params[:id])
              attributes = resource_attributes(model)
              attributes = replacement_attributes(model, attributes) if verb == :put
              record.update(attributes)
              json_response(record.to_detail)
            end
          end

          delete "/#{resource}/:id" do
            find_record(model, params[:id]).destroy
            json_response({ message: 'Deleted' })
          end
        end
      end
    end
  end
end
