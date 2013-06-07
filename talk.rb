require 'sinatra'
require 'twilio-ruby'
require 'cleverbot'

use Rack::Session::Cookie, :path => '/', :expire_after => 2592000, :secret => ENV['SESSION_KEY']

set :public_folder, 'public'

post '/' do
  session['ChatContext'] ||= Marshal.dump Hash.new

  if session['TranscriptionText']
    context = Cleverbot::Client.write(
      session['TranscriptionText'],
      Marshal.load(session['ChatContext'])
    )
    session['ChatContext']       = Marshal.dump context
    session['TranscriptionText'] = ''
    response = context['message']
  else
    response = "Hello, I love you. Talk to me (I'll respond faster if you press pound after speaking)."
  end

  Twilio::TwiML::Response.new do |r|
    r.Say response
    r.Record action: '/wait', maxLength: 10, finishOnKey: '#', transcribeCallback: '/transcribed', playBeep: false
  end.text
end

post '/wait' do
  Twilio::TwiML::Response.new do |r|
    r.Play(request.base_url + '/wait.mp3', loop: 100)
  end.text
end

post '/transcribed' do
  session['TranscriptionText'] = params['TranscriptionText']

  client = Twilio::REST::Client.new params['AccountSid'], ENV['TWILIO_AUTH']
  client.account.calls.get(params['CallSid']).redirect_to request.base_url
end
