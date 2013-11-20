var url = location.host.replace(location.port, window.StandaloneServerPort) + '/websocket',
    dispatcher = new WebSocketRails(url),
    chan = dispatcher.subscribe('twitter'),
    text, tweets, topTweets;

var Tweet = function Tweet(tweet, placement) {
  this.retweetCount = tweet.retweet_count;
  this.name = tweet.name;
  this.text = tweet.text;
  // this.placement = placement;
};

Tweet.prototype.toString = function() {
  // return this.name + ' :: ' + this.text + ' [' + this.retweetCount + '] :: ' + this.placement;
  return this.name + ' :: ' + this.text + ' [' + this.retweetCount + ']';
  // return this.name + ' :: ' + this.text
}

var tweet, $el;
chan.bind('sample', function(data) {
  data = JSON.parse(data);
  tweet = new Tweet(data);
  $el = $('<p>', {class: 'tweet', text: tweet.toString()});
  $('#tweets').append($el)
});
