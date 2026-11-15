# frozen_string_literal: true
# Standalone part 2 exercise; run separately from the recruitment application.
require 'bundler/setup'
require 'sinatra'
require 'sinatra/namespace'
require 'json'

set :port, 4567
set :bind, '127.0.0.1'
before { content_type :json }
get('/') { JSON.generate(message: 'Hello My Sinatra - Easy and Wide world!') }
get('/hello/:name') { JSON.generate(message: "Sinatra приветствует тебя, #{params[:name]}!") }
namespace '/api/v1' do
  get('/*') { JSON.generate(splat: params[:splat]) }
end
get('/*') { JSON.generate(splat: params[:splat]) }
