module Recruitment
  class App
    namespace '/api/v1' do
      get('/company/:id') { json_response(find_record(Company, params[:id]).to_detail) }

      get '/companies/:id/jobs' do
        collection_to_api(find_record(Company, params[:id]).jobs_dataset.order(:id))
      end

      get '/company_jobs' do
        collection_to_api(Company.company_jobs(text_filter(:name)))
      end
    end
  end
end
