var url = location.host.replace(location.port, window.StandaloneServerPort) + '/websocket',
    dispatcher = new WebSocketRails(url),
    chan = dispatcher.subscribe('twitter'),
    text, tweets, topTweets;

var Tweet = function Tweet(tweet, placement) {
  this.retweetCount = tweet.retweet_count;
  this.name = tweet.name;
  this.text = tweet.text;
  this.placement = placement;
};

Tweet.prototype.toString = function() {
  return this.name + ' :: ' + this.text + ' [' + this.retweetCount + '] :: ' + this.placement;
}

// top 10 (incoming)
chan.bind('track_top10', function(data) {
  data = JSON.parse(data); // keys: top_ten, track, filter_change
  topTweets = $.map(data.top_ten, function(tweet, idx) {
    var tweet = new Tweet(tweet, idx+1);
    return $('<p>', {class: 'top-tweet', text: tweet.toString()});
  });
  $('#current-filter').val(data.track);
  $('#tweets').html(topTweets);
});

// filter change (outgoing)
$(function() {
  // todo: disable submit for delay to avoid twitter throttling with too frequent track changes
  $('.submit').click(function() {
    dispatcher.trigger('twitter.filter', {new_track: $('#current-filter').val()});
  });
});
