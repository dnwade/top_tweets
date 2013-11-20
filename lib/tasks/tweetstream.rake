require 'redis'
# require 'socket_twitter'
# binding.pry

namespace :twitter do
  desc 'change twitter filter'
  task :filter_change do
    redis_opts = WebsocketRails.config.redis_options
    redis = Redis.new(:host => redis_opts[:host], :port => redis_opts[:port])
    redis.set("twitter:filter", ["mtv", "nfl", "music", "mongodb"].sample)
  end

  desc 'streaming sample'
  task :sample => :environment do
    require 'socket_twitter'
    # redis_opts = WebsocketRails.config.redis_options
    # redis = Redis.new(:host => redis_opts[:host], :port => redis_opts[:port])

    # prev_filter = (redis.get("twitter:filter") || 'gaga')
    # redis.set("twitter:filter", prev_filter)

    TweetStream::Client.new.sample do |tweet, client|
      # filter = redis.get("twitter:filter")

      if Twitter::Tweet === (retweet = tweet.retweeted_status) && retweet.lang == 'en'
        data = {text: retweet.full_text, name: retweet.user.name, retweet_count: retweet.retweet_count}.to_json
        SocketTwitterWorker.perform_async(data)
      end

      if prev_filter != filter
        prev_filter = filter
        puts "twitter filter CHANGED to #{filter}"
      end
    end
  end

  desc 'simple tracking'
  task :track => :environment do
    TweetStream::Daemon.new('tracker').track('nfl', 'brady') do |status|
      binding.pry
    end
  end
end
