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
  desc 'change twitter filter'
  task :filter_change do
    redis_opts = WebsocketRails.config.redis_options
    redis = Redis.new(:host => redis_opts[:host], :port => redis_opts[:port])
    track = get_track_string(redis)
    pick = ['mtv', 'nfl', 'music', 'nba', 'golf', 'hotel', 'beach', 'kanye'] - [track]
    set_track_string(redis, (track = pick.sample))
    puts "NEW **************  TRACK..... #{track}"
  end


  desc 'twitter track top 10'
  task :track_top10=> :environment do

    redis_opts = WebsocketRails.config.redis_options
    redis = Redis.new(:host => redis_opts[:host], :port => redis_opts[:port])

    # initial track string
    track = get_track_string(redis) || (set_track_string(redis, 'voice') && 'voice')
    top_ten = TopTweet.find_or_create_by(filter: track)

    # push existing to client
    data = {top_ten: top_ten.sorted_tweets, track: track, filter_change: true}
    WebsocketRails[:twitter].trigger :track_top10, data.to_json

    client = TweetStream::Client.new

    # handle filter change
    client.on_inited do
      timer = EM::PeriodicTimer.new(TRACK_UPDATE_POLL_INTERVAL) do
        if track != (track = get_track_string(redis))
          client.stream.update(:params => {:track => track})
          top_ten = TopTweet.find_or_create_by(filter: track)
          data = {top_ten: top_ten.sorted_tweets, track: track, filter_change: true}
          WebsocketRails[:twitter].trigger :track_top10, data.to_json
        end
      end
    end

    # handle streaming tweets
    client.track(track) do |tweet, client|
      if Twitter::Tweet === (retweet = tweet.retweeted_status) && retweet.lang == 'en'
        if top_ten.examine(retweet)
          # puts top_ten.to_s
          data = {top_ten: top_ten.sorted_tweets, track: track, filter_change: false}
          WebsocketRails[:twitter].trigger :track_top10, data.to_json
        end
      end
    end
  end


  desc 'twitter filter tracking'
  task :track_streaming => :environment do

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
          data = {:name => "**********   META   *****", :text => "NEW TRACK '#{track}'", :retweet_count => 1}.to_json
          WebsocketRails[:twitter].trigger :track_streaming, data
        end
      end
    end

    client.track(track) do |tweet, client|
      if Twitter::Tweet === (retweet = tweet.retweeted_status) && retweet.lang == 'en'
        data = {text: ("[#{track}]  " + retweet.full_text), name: retweet.user.name, retweet_count: retweet.retweet_count}.to_json
        WebsocketRails[:twitter].trigger :track_streaming, data
      end
    end
  end
end
