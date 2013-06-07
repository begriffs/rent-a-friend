require 'sinatra'
require 'builder'
require 'cleverbot'

enable :sessions
set :session_secret, ENV['SESSION_KEY']

post '/' do
  session[:chat_context] = Marshal.dump Hash.new
  builder do |xml|
    xml.instruct!
    xml.Response do
      xml.Say "Hello, I love you. Talk to me. (I'll respond faster if you press pound after speaking.)"
      xml.Record(maxLength: 10, finishOnKey: '#', transcribeCallback: '/reply', playBeep: false)
    end
  end
end

post '/reply' do
  context = Cleverbot::Client.write params[:TranscriptionText], Marshal.load(session[:chat_context])
  session[:chat_context] = Marshal.dump context
  builder do |xml|
    xml.instruct!
    xml.Response do
      xml.Say context[:message]
      xml.Record(maxLength: 10, finishOnKey: '#', transcribeCallback: '.', playBeep: false)
    end
  end
end
