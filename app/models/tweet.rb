class Tweet
  include Mongoid::Document
  embedded_in :top_tweet

  field :name, type: String
  field :text, type: String
  field :retweet_count, type: Integer
end
