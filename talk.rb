require 'sinatra'
require 'twilio-ruby'
require 'cleverbot'
require 'dalli'
require 'memcachier'

set :cache, Dalli::Client.new
set :public_folder, 'public'
# Go easy on Twilio's bandwidth, allow them to cache the hold-music mp3
set :static_cache_control, [:public, max_age: 60 * 60 * 24 * 365]

post '/' do
  Twilio::TwiML::Response.new do |r|
    r.Say settings.cache.get(params['CallSid'] + 'reply') || "Hello, I love you. Talk to me."
    r.Redirect '/listen'
  end.text
end

post '/listen' do
  Twilio::TwiML::Response.new do |r|
    r.Record action: '/wait', maxLength: 10, timeout: 2, transcribeCallback: '/transcribed', playBeep: false
    r.Redirect '/listen' # retry the recording if the user doesn't speak
  end.text
end

post '/wait' do
  Twilio::TwiML::Response.new do |r|
    r.Play(request.base_url + '/wait.mp3', loop: 100)
  end.text
end

post '/transcribed' do
  call_sid = params['CallSid']
  context  = Cleverbot::Client.write(
    params['TranscriptionText'],
    Marshal.load(settings.cache.get(call_sid + 'chat') || Marshal.dump(Hash.new))
  )

  settings.cache.set(call_sid + 'chat', Marshal.dump(context))
  settings.cache.set(call_sid + 'reply', context['message'].strip)

  client = Twilio::REST::Client.new params['AccountSid'], ENV['TWILIO_AUTH']
  client.account.calls.get(call_sid).redirect_to request.base_url
end
