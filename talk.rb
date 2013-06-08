require 'sinatra'
require 'twilio-ruby'
require 'cleverbot'
require 'dalli'
require 'memcachier'

set :cache, Dalli::Client.new
set :public_folder, 'public'

post '/' do
  call_sid      = params['CallSid']
  context       = Marshal.load(settings.cache.get(call_sid + 'chat') || Marshal.dump(Hash.new))
  transcription = settings.cache.get(call_sid + 'transcription')

  if transcription
    context = Cleverbot::Client.write(transcription, context)
    settings.cache.set(call_sid + 'chat', Marshal.dump(context))
    settings.cache.set(call_sid + 'transcription', nil)
    response = context['message']
  else
    response = "Hello, I love you. Talk to me."
  end

  Twilio::TwiML::Response.new do |r|
    r.Say response
    r.Record action: '/wait', maxLength: 10, timeout: 3, finishOnKey: '#', transcribeCallback: '/transcribed', playBeep: false
  end.text
end

post '/wait' do
  Twilio::TwiML::Response.new do |r|
    r.Play(request.base_url + '/wait.mp3', loop: 100)
  end.text
end

post '/transcribed' do
  settings.cache.set(params['CallSid'] + 'transcription', params['TranscriptionText'])

  client = Twilio::REST::Client.new params['AccountSid'], ENV['TWILIO_AUTH']
  client.account.calls.get(params['CallSid']).redirect_to request.base_url
end
