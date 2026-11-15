module Recruitment
  class App
    get('/') { json_response(message: 'Hi! I am api_sinatra_postgres!') }
    get('/hello/:name') { |name| json_response(message: "Sinatra приветствует тебя, #{name}!") }
    get '/redirect' do
      headers 'Location' => to('/hello/World')
      json_response({ redirect: '/hello/World' }, 302)
    end
    get('/players/:sport_id') { json_response(sport_id: params[:sport_id]) }
    get('/players/*/:year') { json_response(splat: params[:splat], year: params[:year]) }
    get('/say/*/to/*') { json_response(splat: params[:splat]) }
    get('/download/*.*') { |path, ext| json_response(path: path, ext: ext) }
    get(%r{/meta/hello/([\w]+)(?:/world)?}) { |word| json_response(message: "Hello, #{word}!") }
    get(%r{/hello/([\w]+)/([\d]+)}) { |word, number| json_response(message: "Hello, #{word}!", number: number) }
    get('/jobs.?:format?') { json_response(message: 'Да, работает этот маршрут!', format: params[:format]) }

    ['/friends', '/api/v1/friends'].each do |path|
      get(path) { json_response(message: "I don't know what is the [\"friends\"]. It's what you typed.", splat: ['friends']) }
    end
  end
end
