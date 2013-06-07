require 'sinatra'
require 'builder'

enable :sessions
set :session_secret, ENV['SESSION_KEY']

post '/' do
  builder do |xml|
    xml.instruct!
    xml.Response do
      xml.Say("Hello world")
    end
  end
end
