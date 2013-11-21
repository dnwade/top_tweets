# Top Tweet Streamer

Updates top tweets in realtime. Search twitter for the top tweets (based on the number of retweets).

Uses websockets, rails, redis, and mongodb. In particular [websocket-rails](https://github.com/websocket-rails/websocket-rails) and [tweetstream](https://github.com/tweetstream/tweetstream)

## Getting Started
* install Mongo
* install Redis
* Clone repository
* Run bundler: ```bundle```
* add your twitter api credentials: ```cp config/initializers/tweetstream.rb.example config/initializers/tweetstream.rb```
* Start rails: ```rails s```
* Start foreman: ```foreman start```
