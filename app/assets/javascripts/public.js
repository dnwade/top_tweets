var url = location.host.replace(location.port, window.StandaloneServerPort) + '/websocket',
    dispatcher = new WebSocketRails(url),
    chan = dispatcher.subscribe('twitter'),
    text, tweets, topTweets, tweet, ul, li, tweet_container, tweet_text, tweet_count, tweet_author;

var Tweet = function Tweet(tweet, placement) {
  this.retweetCount = tweet.retweet_count;
  this.name = tweet.name;
  this.text = tweet.text;
  this.placement = placement;
};

Tweet.prototype.toString = function() {
  return this.name + ' :: ' + this.text + ' [' + this.retweetCount + '] :: ' + this.placement;
}

Tweet.prototype.toHtml = function() {
  var container, text, retweetCount, author, tweetMeta;
  container = $('<li class="Tweet list-group-item">');
  text = $('<blockquote">').append($('<p>', {class: 'Tweet-text', text: this.text}));
  tweetMeta = $('<small>');
  author = $('<cite>', {class: 'Tweet-author', text: this.name});
  retweetCount = $('<span>', {class: 'Tweet-count badge', text: this.retweetCount});
  tweetMeta.append(author).append(retweetCount);
  text.append(tweetMeta);
  return container.append(text);
}

// top 10 (incoming)
chan.bind('track_top10', function(data) {
  var tweetsContainer;
  tweetsContainer = $('<ul class="top-tweets list-group">');
  data = JSON.parse(data); // keys: top_ten, track, filter_change
  $.each(data.top_ten, function(idx, tweet) {
    tweet = new Tweet(tweet, idx+1);
    tweetsContainer.append(tweet.toHtml()); // respects order
  });
  $('.js-currentFilter').text(data.track);
  $('.js-tweets').html(tweetsContainer);
});

// filter change (outgoing)
$(function() {
  // todo: disable submit for delay to avoid twitter throttling with too frequent track changes
  $('.js-updateFilter').submit(function() {
    dispatcher.trigger('twitter.filter', {new_track: $('#current-filter').val()});
    return false;
  });
});
