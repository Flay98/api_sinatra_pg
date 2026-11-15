require_relative 'environment'

bind "tcp://127.0.0.1:#{ENV.fetch('PORT', '4567')}"
threads 1, 5
environment ENV.fetch('RACK_ENV', 'development')
