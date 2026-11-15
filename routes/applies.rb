module Recruitment
  class App
    namespace '/api/v1' do
      get('/apply/:id') { json_response(find_record(Apply, params[:id]).to_detail) }
      get('/applies_read') { collection_to_api(Apply.read.order(:id)) }
      get('/applies_unread') { collection_to_api(Apply.unread.order(:id)) }
    end
  end
end
