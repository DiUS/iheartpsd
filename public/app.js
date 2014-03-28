$(document).ready(function() {
  $('.text').tooltip({
    html: true,
    trigger: 'click'
  });

  ZeroClipboard.config({ moviePath: "/vendor/zeroclipboard/ZeroClipboard.swf" });
  var client = new ZeroClipboard();

  client.on( 'dataRequested', function (client, args) {
    client.setText( "Copy me!" );
  });

  // client.clip( $('.text') );
  // $('.text').click(function() {
  //   console.log(this);
  //   client.setText('asdfa');
  // });
});