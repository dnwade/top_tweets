require 'redis'
TRACK_UPDATE_POLL_INTERVAL = 1 # seconds
REDIS_TRACK_KEY = "twitter:filter"

def get_track_string(redis)
  redis.get(REDIS_TRACK_KEY)
end

def set_track_string(redis, value)
  redis.set(REDIS_TRACK_KEY, value)
end

namespace :twitter do

  desc 'twitter track top 10'
  task :track_top10=> :environment do

    redis_opts = WebsocketRails.config.redis_options
    redis = Redis.new(:host => redis_opts[:host], :port => redis_opts[:port])

    # initial track string
    track = get_track_string(redis) || (set_track_string(redis, 'voice') && 'voice')
    top_ten = TopTweet.find_or_create_by(filter: track)

    # push existing to client
    data = {top_ten: top_ten.sorted_tweets, track: track, filter_change: true}
    WebsocketRails[:twitter].trigger :track_top10, data

    client = TweetStream::Client.new

    # handle filter change
    client.on_inited do
      timer = EM::PeriodicTimer.new(TRACK_UPDATE_POLL_INTERVAL) do
        if track != (track = get_track_string(redis))
          client.stream.update(:params => {:track => track})
          top_ten = TopTweet.find_or_create_by(filter: track)
          data = {top_ten: top_ten.sorted_tweets, track: track, filter_change: true}
          WebsocketRails[:twitter].trigger :track_top10, data
        end
      end
    end

    # handle streaming tweets
    client.track(track) do |tweet, client|
      if Twitter::Tweet === (retweet = tweet.retweeted_status) && retweet.lang == 'en'
        if top_ten.examine(retweet)
          data = {top_ten: top_ten.sorted_tweets, track: track, filter_change: false}
          WebsocketRails[:twitter].trigger :track_top10, data
        end
      end
    end
  end
end
