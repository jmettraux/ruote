
//
// pilatus.js
//
// (c) 2008 John Mettraux 
// http://github.com/jmettraux/pilatus
//
// License is MIT
//

var Pilatus = function() {

  var cssPrefix = 'pilatus';

  function setCssPrefix (p) { cssPrefix = p; }

  var itemKeys = [
    [ 'title' ],
    [ 'link' ],
    [ 'author', 'name' ],
    [ 'pubDate' ],
    //[ 'content', 'content' ],
    [ 'description' ]
  ];

  function setItemKeys (ik) {
    itemKeys = ik;
  }

  var maxEntries = null;

  function setMaxEntries (i) {
    maxEntries = i;
  }

  function createElt (parentElt, eTag, eAttributes, eText) {
    var e = document.createElement(eTag);
    if (eAttributes) {
      for (var k in eAttributes) { e.setAttribute(k, eAttributes[k]); }
    }
    if (eText) e.text = eText;
    parentElt.appendChild(e);
    return e;
  }

  function loadAndRender (parentDivId, pipeUrl) {

    var t = (new Date()).getTime();
    var callbackName = "_" + t + "_pilatus_callback";

    createElt(
      document.body,
      //document.getElementsByTagName('head')[0],
      'script',
      { 'type': 'text/javascript' },
      "function " + callbackName + " (json) {"+
      " Pilatus.render('"+parentDivId+"', json); }");

    pipeUrl += ('&_render=json&_callback=' + callbackName);

    createElt(
      document.body,
      //document.getElementsByTagName('head')[0],
      'script',
      { 'type': 'text/javascript', 'src': pipeUrl });
  }

  function linkInnerHtml (item) {
    return '<a href="' + item.link + '">' + item.link + '</a>';
  }

  function render (parentDivId, json) {

    var l = json.value.items.length;
    if (maxEntries && l > maxEntries) l = maxEntries;

    var parentDiv = document.getElementById(parentDivId);

    for (var i=0; i < l; i++) {

      var item = json.value.items[i];

      var eEntry = createElt(
        parentDiv, 'div', { 'class': cssPrefix + '_entry' });

      for (var j in itemKeys) {
        var k = itemKeys[j];
        var kl = cssPrefix + '_' + k.join('_');
        var sk = k[1];
        k = k[0];
        var v = item[k];
        if (v && sk) v = v[sk];
        if (k == 'link') v = linkInnerHtml(item);
        //createElt(eEntry, 'div', { 'class': kl }, v);
        createElt(eEntry, 'div', { 'class': kl }).innerHTML = v;
      }
    }
  }

  return { 
    render: render,
    loadAndRender: loadAndRender,
    setCssPrefix: setCssPrefix,
    setItemKeys: setItemKeys,
    setMaxEntries: setMaxEntries
  };
}();

