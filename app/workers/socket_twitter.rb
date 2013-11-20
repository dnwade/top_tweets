class SocketTwitterWorker
  include Sidekiq::Worker

  def perform(tweet_json)
    WebsocketRails[:twitter].trigger :sample, tweet_json
  end
end
