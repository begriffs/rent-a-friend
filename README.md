<img src="creepy-robot-friend.png" alt="Groupthink Logo" align="right" />
## Your new best friend

When you need a friend in whom to confide your closest secrets, try a
robot. Deploy this Sinatra app to talk with you through Twilio. Its
artificial emotions are always there for you.

## How to awaken your own

Deploy this app to Heroku:

    heroku create
    heroku config:add SESSION_KEY=`head -c 32 /dev/random | base64`
    git push heroku master
