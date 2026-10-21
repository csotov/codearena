// CodeArena web worker: runs JSCPP off the UI thread so the judge
// can enforce a wall-clock timeout (terminate()) and step limit.
// Flutter web serves bundled assets under assets/<source-path>.
importScripts('assets/assets/vendor/JSCPP.es5.min.js');
importScripts('assets/assets/vendor/runner.js');

self.onmessage = function (e) {
  var m = e.data;
  try {
    var result = codeArenaRun(m.code, m.input, m.maxSteps || 2000000);
    self.postMessage(result);
  } catch (err) {
    self.postMessage(JSON.stringify({
      ok: false,
      error: 'ENGINE',
      detail: String(err),
      output: ''
    }));
  }
};
