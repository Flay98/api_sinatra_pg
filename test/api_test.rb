# frozen_string_literal: true

require_relative 'test_helper'

class ResourcesTest < ApiTest
  def test_rack_entrypoint_loads
    require 'rack/builder'
    rack_app = Rack::Builder.parse_file(File.join(Recruitment::ROOT, 'config.ru'))
    assert_respond_to rack_app, :call
  end

  FIXTURES = {
    'companies' => [{ name: 'Test Co', location: 'Moscow' }, { location: 'Kazan' }, 4],
    'jobs' => [{ name: 'Ruby', place: 'Remote', company_id: 1 }, { place: 'Contract' }, 7],
    'geeks' => [{ name: 'Test Geek', stack: 'Ruby', resume: true }, { stack: 'Sinatra' }, 9],
    'applies' => [{ job_id: 1, geek_id: 9, read: false, invited: false }, { read: true }, 4]
  }.freeze

  FIXTURES.each do |resource, (attributes, changes, count)|
    define_method("test_#{resource}_list_and_detail") do
      get "/api/v1/#{resource}"
      list = assert_json_status(200)
      assert_equal count, list.length
      assert_equal 1, list.first['id']
      refute list.first.key?('created_at')
      get "/api/v1/#{resource}/1"
      detail = assert_json_status(200)
      assert_equal 1, detail['id']
      assert detail.key?('created_at')
    end

    define_method("test_#{resource}_create_update_delete") do
      send_json(:post, "/api/v1/#{resource}", attributes)
      record = assert_json_status(201)
      id = record.fetch('id')
      assert_equal "/api/v1/#{resource}/#{id}", last_response['Location']
      attributes.each { |key, value| assert_equal value, record[key.to_s] }
      %i[patch put].each do |verb|
        payload = verb == :put ? attributes.merge(changes) : changes
        send_json(verb, "/api/v1/#{resource}/#{id}", payload)
        result = assert_json_status(200)
        changes.each { |key, value| assert_equal value, result[key.to_s] }
      end
      delete "/api/v1/#{resource}/#{id}"
      assert_json_status(200)
      get "/api/v1/#{resource}/#{id}"
      assert_json_status(404)
    end

    define_method("test_#{resource}_missing_record_and_id") do
      get "/api/v1/#{resource}/2000000000"
      result = assert_json_status(404)
      assert_equal '2000000000', result['params_id']
      get "/api/v1/#{resource}/abc"
      assert_json_status(400)
      get "/api/v1/#{resource}/0"
      assert_json_status(400)
    end

    define_method("test_#{resource}_unknown_attributes") do
      send_json(:post, "/api/v1/#{resource}", attributes.merge(id: 111))
      assert_equal ['id'], assert_json_status(422)['attributes']
    end
  end

  def test_singular_aliases
    %w[company job geek apply].each do |resource|
      get "/api/v1/#{resource}/1"
      assert_equal 1, assert_json_status(200)['id']
      get "/api/v1/#{resource}/2000000000"
      assert_equal 'Document Not Found', assert_json_status(404)['message']
    end
  end

  def test_put_replaces_attributes_and_patch_updates_selected_attributes
    send_json(:put, '/api/v1/companies/1', location: 'Moscow')
    assert_json_status(422)
    assert_equal 'MoGo', Recruitment::Company[1].name
    send_json(:patch, '/api/v1/companies/1', location: 'Moscow')
    assert_equal 'MoGo', assert_json_status(200)['name']
    send_json(:put, '/api/v1/geeks/1', name: 'Peter', stack: 'Ruby')
    assert_equal false, assert_json_status(200)['resume']
  end

  def test_company_filters_and_empty_results
    { 'name=Mo' => [1], 'location=lon' => [2, 4], 'name=Mo&location=Ne' => [1],
      'name=Mo;location=Ne' => [1], 'name=Mo;location=Si' => [], 'name=Q' => [] }.each do |query, ids|
      get "/api/v1/companies?#{query}"
      assert_equal ids, assert_json_status(200).map { |item| item['id'] }
    end
  end

  def test_job_filters_chain_and_empty_company
    { 'place=Remo' => [1, 3, 5], 'name=Ruby' => [2, 5], 'place=Remote&name=Ruby' => [5],
      'company=Mo' => [1, 4], 'company=' => (1..7).to_a, 'company=Missing' => [],
      'company_id=2' => [2] }.each do |query, ids|
      get "/api/v1/jobs?#{query}"
      assert_equal ids, assert_json_status(200).map { |item| item['id'] }
    end
  end

  def test_company_jobs_routes
    ['/api/v1/companies/1/jobs', '/api/v1/company_jobs?name=Mo', '/api/v1/jobs_company/MoGo'].each do |path|
      get path
      assert_equal [1, 4], assert_json_status(200).map { |item| item['id'] }
    end
    get '/api/v1/company_jobs?name=Missing'
    assert_equal [], assert_json_status(200)
    get '/api/v1/jobs_company/Missing'
    assert_json_status(404)
    company = Recruitment::Company.create(name: 'No jobs', location: 'Here')
    get "/api/v1/companies/#{company.id}/jobs"
    assert_equal [], assert_json_status(200)
    get '/api/v1/jobs_company/No%20jobs'
    assert_equal [], assert_json_status(200)
  end

  def test_company_jobs_collects_all_matching_companies
    get '/api/v1/company_jobs?name=i'
    assert_equal [2, 3, 5, 6, 7], assert_json_status(200).map { |item| item['id'] }
  end

  def test_read_unread_and_boolean_json
    get '/api/v1/applies_read'
    assert_equal [1, 3], assert_json_status(200).map { |item| item['id'] }
    assert_equal true, body.first['read']
    assert_equal false, body.first['invited']
    get '/api/v1/applies_unread'
    assert_equal [2, 4], assert_json_status(200).map { |item| item['id'] }
    get '/api/v1/applies?read=true&invited=true&job_id=1'
    assert_equal [3], assert_json_status(200).map { |item| item['id'] }
    get '/api/v1/applies?geek_id=1'
    assert_equal [1, 4], assert_json_status(200).map { |item| item['id'] }
  end

  def test_geek_filters_and_nested_routes
    get '/api/v1/geeks?stack=Ruby&resume=false'
    assert_equal [6], assert_json_status(200).map { |item| item['id'] }
    get '/api/v1/geeks?name=pet'
    assert_equal [1], assert_json_status(200).map { |item| item['id'] }
    { '/api/v1/geeks/1/jobs' => [1, 3], '/api/v1/geeks/1/applies' => [1, 4],
      '/api/v1/jobs/1/applies' => [1, 3] }.each do |path, ids|
      get path
      assert_equal ids, assert_json_status(200).map { |item| item['id'] }
    end
  end

  def test_post_company_query_and_form_examples
    post '/api/v1/companies?name=Dieter&location=Ubud'
    assert_equal 'Dieter', assert_json_status(201)['name']
    post '/api/v1/companies', { name: 'Form Co', location: 'Ubud' }
    assert_equal 'Form Co', assert_json_status(201)['name']
  end

  def test_validation_failure_and_bad_reference
    send_json(:post, '/api/v1/companies', name: ' ')
    result = assert_json_status(422)
    assert result['errors'].key?('name')
    assert result['errors'].key?('location')
    send_json(:post, '/api/v1/jobs', name: 'Ruby', place: 'Remote', company_id: 2000000000)
    assert_json_status(422)
    send_json(:post, '/api/v1/geeks', name: 'Ruby', stack: 'Ruby', resume: 'maybe')
    assert_json_status(422)
  end

  def test_json_parser_errors
    post '/api/v1/companies', '{', 'CONTENT_TYPE' => 'application/json'
    assert_equal 'Malformed JSON', assert_json_status(400)['message']
    [[], nil, 123, 'test'].each do |value|
      send_json(:post, '/api/v1/companies', value)
      assert_json_status(400)
    end
    post '/api/v1/companies', 'name=test', 'CONTENT_TYPE' => 'text/plain'
    assert_json_status(415)
  end

  def test_attribute_types_and_invalid_filters
    send_json(:post, '/api/v1/companies', name: ['test'], location: 'City')
    assert_json_status(422)
    send_json(:post, '/api/v1/jobs', name: 'Ruby', place: 'Remote', company_id: 1.5)
    assert_json_status(400)
    ['/api/v1/companies?name[]=Mo', '/api/v1/jobs?company_id=nope',
     '/api/v1/jobs/99999999999999999999999'].each do |path|
      get path
      assert_json_status(400)
    end
    get '/api/v1/applies?read=maybe'
    assert_json_status(422)
  end

  def test_literal_search_is_not_regex_sql_or_wildcard
    ["' OR 1=1 --", '%', '_', '[', '\\'].each do |value|
      get '/api/v1/companies', name: value
      assert_equal [], assert_json_status(200)
    end
    assert_equal 4, Recruitment::Company.count
  end

  def test_deleting_referenced_company_returns_conflict
    delete '/api/v1/companies/1'
    assert_json_status(409)
    # A PostgreSQL error must not poison the next request's connection.
    get '/api/v1/companies/1'
    assert_json_status(200)
  end

  def test_unknown_route_is_json
    get '/api/v1/no_such_route'
    result = assert_json_status(404)
    assert_equal 'Route Not Found', result['message']
  end

  def test_options_and_head
    options '/api/v1/companies'
    assert_includes assert_json_status(200)['methods'], 'POST'
    assert_includes last_response['Allow'], 'DELETE'
    head '/api/v1/companies'
    assert_equal 200, last_response.status
    assert_empty last_response.body
  end
end
