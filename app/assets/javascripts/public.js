var url = location.host.replace(location.port, window.StandaloneServerPort) + '/websocket',
    dispatcher = new WebSocketRails(url),
    chan = dispatcher.subscribe('twitter');

// http://stackoverflow.com/questions/2901102/how-to-print-a-number-with-commas-as-thousands-separators-in-javascript
function numberWithCommas(x) {
    return x.toString().replace(/\B(?=(\d{3})+(?!\d))/g, ",");
}

var Tweet = function Tweet(tweet, placement) {
  this.retweetCount = numberWithCommas(tweet.retweet_count);
  this.name = tweet.name;
  this.text = tweet.text;
  this.placement = placement;
};

Tweet.prototype.toHtml = function() {
  var container, text, retweetCount, author, tweet, textWrap;
  container = $('<li class="Tweet">');
  tweet = $('<blockquote>');

  text = $('<p>', {class: 'Tweet-text', text: this.text});
  retweetCount = $('<span>', {class: 'Tweet-count badge', text: this.retweetCount});
  text.append(retweetCount);

  authorBlock = $('<small class="alert alert-info">');
  author = $('<cite>', {class: 'Tweet-author', text: this.name});
  authorBlock.append(author);

  tweet.append(text).append(author);
  return container.append(tweet);
}

dispatcher.on_open = function(data) {
  console.log("on open", data);
  dispatcher.trigger('twitter.send_latest');
};

// top 10 (incoming)
chan.bind('track_top10', function(data) {
  var tweetsContainer = $('.top-tweets');
  tweetsContainer.html('');
  if (typeof data === 'string') data = JSON.parse(data);
  $.each(data.top_ten, function(idx, tweet) {
    tweet = new Tweet(tweet, idx+1);
    tweetsContainer.append(tweet.toHtml()); // respects order
  });
  $('.js-currentFilter').text(data.track);
});

// filter change (outgoing)
$(function() {
  // todo: disable submit for delay to avoid twitter throttling with too frequent track changes
  $('.js-updateFilter').submit(function() {
    dispatcher.trigger('twitter.filter', {new_track: $('#current-filter').val()});
    $('.top-tweets').html('');
    return false;
  });
});
