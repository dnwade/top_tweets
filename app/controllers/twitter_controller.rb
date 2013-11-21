class TwitterController < WebsocketRails::BaseController
  def filter_change
    set_track_string(data["new_track"])
  end

  # todo: dry (between this & tweetstream.rake)
  def client_connected
    track = get_track_string || (set_track_string('voice') && 'voice')
    top_ten = TopTweet.find_or_create_by(filter: track)

    # push existing to client
    data = {top_ten: top_ten.sorted_tweets, track: track, filter_change: true}
    WebsocketRails[:twitter].trigger :track_top10, data.to_json
  end

  private
  def set_track_string(value)
    redis.set(REDIS_TRACK_KEY, value)
  end

  def get_track_string
    redis.get(REDIS_TRACK_KEY)
  end

  def redis
    @redis_opts ||= WebsocketRails.config.redis_options
    @redis ||= Redis.new(:host => @redis_opts[:host], :port => @redis_opts[:port])
  end
end
