// Generated by CoffeeScript 1.4.0
(function() {
  var ShowdownLive;

  ShowdownLive = (function() {

    function ShowdownLive(selector) {
      var converter, html, livenode;
      this.selector = selector;
      $(this.selector).css('display', 'none');
      livenode = $('<div contenteditable="true" class="post_content"></div>');
      livenode.insertAfter(this.selector);
      converter = new Showdown.converter();
      html = converter.makeHtml($(this.selector).val());
      livenode.html(html);
      this.log("Initing " + this.selector + " as ShowdownLive");
    }

    ShowdownLive.prototype.log = function(message) {
      return console.log(message);
    };

    return ShowdownLive;

  })();

  window.ShowdownLive = ShowdownLive;

}).call(this);