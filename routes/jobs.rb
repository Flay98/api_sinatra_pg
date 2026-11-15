module Recruitment
  class App
    namespace '/api/v1' do
      get('/job/:id') { json_response(find_record(Job, params[:id]).to_detail) }

      get '/jobs_company/:name' do
        company = Company.first(name: params[:name])
        api_error(404, 'Company Document Not Found', params_id: params[:name]) unless company
        collection_to_api(company.jobs_dataset.order(:id))
      end

      get '/jobs/:id/applies' do
        collection_to_api(find_record(Job, params[:id]).applies_dataset.order(:id))
      end
    end
  end
end
