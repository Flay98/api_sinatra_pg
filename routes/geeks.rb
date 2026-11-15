module Recruitment
  class App
    namespace '/api/v1' do
      get('/geek/:id') { json_response(find_record(Geek, params[:id]).to_detail) }
      get('/geeks/:id/jobs') { collection_to_api(find_record(Geek, params[:id]).jobs_dataset.order(:id)) }
      get('/geeks/:id/applies') { collection_to_api(find_record(Geek, params[:id]).applies_dataset.order(:id)) }
    end
  end
end
