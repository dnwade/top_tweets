require 'redis'
TRACK_UPDATE_POLL_INTERVAL = 1 # seconds
REDIS_TRACK_KEY = "twitter:filter"

def get_track_string(redis)
  redis.get(REDIS_TRACK_KEY)
end

def set_track_string(redis, value)
  redis.set(REDIS_TRACK_KEY, value)
end

def push_tweet(redis, json)
  redis.rpush(REDIS_TRACK_QUEUE_KEY, json)
end

def pop_tweet(redis)
  redis.blpop(REDIS_TRACK_QUEUE_KEY)
end

namespace :twitter do
  desc 'change twitter filter'
  task :filter_change do
    redis_opts = WebsocketRails.config.redis_options
    redis = Redis.new(:host => redis_opts[:host], :port => redis_opts[:port])
    track = get_track_string(redis)
    pick = ['mtv', 'nfl', 'music', 'nba', 'golf', 'hotel', 'beach', 'kanye'] - [track]
    set_track_string(redis, (track = pick.sample))
    puts "NEW **************  TRACK..... #{track}"
  end


  desc 'twitter filter tracking'
  task :track => :environment do

    redis_opts = WebsocketRails.config.redis_options
    redis = Redis.new(:host => redis_opts[:host], :port => redis_opts[:port])

    set_track_string(redis, 'voice')
    track = get_track_string(redis) || 'voice'
    set_track_string(redis, track)

    client = TweetStream::Client.new
    client.on_inited do
      timer = EM::PeriodicTimer.new(TRACK_UPDATE_POLL_INTERVAL) do
        if track != (track = get_track_string(redis))
          client.stream.update(:params => {:track => track})
          data = {:name => "**********   META   *****", :text => "NEW TRACK '#{track}' vs '#{get_track_string(redis)}'", :retweet_count => 1}.to_json
          WebsocketRails[:twitter].trigger :track, data
        end
      end
    end

    client.track(track) do |tweet, client|
      if Twitter::Tweet === (retweet = tweet.retweeted_status) && retweet.lang == 'en'
        data = {text: ("[#{track}]  " + retweet.full_text), name: retweet.user.name, retweet_count: retweet.retweet_count}.to_json
        WebsocketRails[:twitter].trigger :track, data
      end
    end
  end
end
