require_relative 'test_helper'

class ExamplesTest < ApiTest
  def test_greeting_named_parameter_and_redirect
    get '/'
    assert_equal 'Hi! I am api_sinatra_postgres!', assert_json_status(200)['message']
    get '/hello/Peter'
    assert_includes assert_json_status(200)['message'], 'Peter'
    get '/redirect'
    assert_json_status(302)
    follow_redirect!
    assert_includes assert_json_status(200)['message'], 'World'
  end

  def test_splats_and_block_arguments
    get '/say/hello/to/world'
    assert_equal %w[hello world], assert_json_status(200)['splat']
    get '/download/path/to/file.xml'
    assert_equal({ 'path' => 'path/to/file', 'ext' => 'xml' }, assert_json_status(200))
    get '/players/football'
    assert_equal 'football', assert_json_status(200)['sport_id']
    get '/players/performances/2016'
    assert_equal ['performances'], assert_json_status(200)['splat']
    assert_equal '2016', body['year']
  end

  def test_regex_and_optional_parameters
    ['/meta/hello/world', '/meta/hello/12345/world', '/hello/world/1234'].each do |path|
      get path
      assert_json_status(200)
    end
    ['/jobs', '/jobs.json', '/jobs.xml'].each do |path|
      get path
      assert_equal 'Да, работает этот маршрут!', assert_json_status(200)['message']
    end
  end

  def test_namespace_examples
    ['/friends', '/api/v1/friends'].each do |path|
      get path
      assert_equal ['friends'], assert_json_status(200)['splat']
    end
  end
end
