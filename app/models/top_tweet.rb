class TopTweet
  MAXLEN = 10
  include Mongoid::Document

  embeds_many :tweets, validate: false
  field :filter, type: String

  def sorted_tweets
    tweets.desc(:retweet_count)
  end

  def examine(tweet)
    matching = tweets.where(text: tweet.text)
    if matching.size > 0
      matching[0].retweet_count = tweet.retweet_count # update
    elsif tweets.size < MAXLEN
      tweets.build(retweet_count: tweet.retweet_count, text: tweet.text, name: tweet.user.name)
    # elsif sorted_tweets.last.retweet_count < tweet.retweet_count
    elsif (min_retweet = tweets.min(:retweet_count)) < tweet.retweet_count
      rejected = tweets.where(retweet_count: min_retweet)[0]
      rejected.delete
      tweets.build(retweet_count: tweet.retweet_count, text: tweet.text, name: tweet.user.name)
    else
      return false
    end
    save
    return true
  end

  def to_s
    sorted_tweets.each_with_index.map do |tweet, i|
      "#{tweet.name} :: #{tweet.text} :: #{tweet.retweet_count}"
    end.join("\n") + "\n"
  end
end
