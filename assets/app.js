(function () {
  'use strict';
  // Copy-link buttons
  document.querySelectorAll('[data-copy]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var input = document.getElementById(btn.getAttribute('data-copy'));
      input.select();
      var done = function () { btn.textContent = 'Copied'; setTimeout(function () { btn.textContent = 'Copy'; }, 1500); };
      if (navigator.clipboard) { navigator.clipboard.writeText(input.value).then(done, function () { document.execCommand('copy'); done(); }); }
      else { document.execCommand('copy'); done(); }
    });
  });

  // Note toggles
  document.querySelectorAll('.note-toggle').forEach(function (b) {
    b.addEventListener('click', function () {
      var note = b.closest('.q').querySelector('textarea.note');
      note.classList.toggle('open');
      if (note.classList.contains('open')) note.focus();
    });
  });

  // Mark answered questions as you go
  function refresh(q) {
    var filled = false;
    q.querySelectorAll('input, textarea').forEach(function (el) {
      if (el.classList.contains('note') || el.closest('.heart')) return;
      if ((el.type === 'radio' || el.type === 'checkbox') ? el.checked : el.value.trim() !== '') filled = true;
    });
    q.classList.toggle('answered', filled);
    if (filled) q.classList.remove('missing');
    var h = q.querySelector('.heart input');
    if (h) q.classList.toggle('hearted', h.checked);
  }
  document.querySelectorAll('.q').forEach(function (q) {
    refresh(q);
    q.addEventListener('change', function () { refresh(q); });
  });

  // Autosave on the main quiz so nothing is lost on a phone
  var form = document.querySelector('form.autosave');
  if (form && window.fetch && window.FormData) {
    var timer = null, note = form.querySelector('.saved-note');
    var save = function () {
      var fd = new FormData(form);
      fd.delete('nav');
      fetch(form.action, { method: 'POST', body: fd, credentials: 'same-origin', headers: { 'X-Requested-With': 'fetch' } })
        .then(function (r) { if (note) note.textContent = r.ok ? 'Saved' : 'Not saved, press Next to save'; })
        .catch(function () { if (note) note.textContent = 'Offline, press Next to save'; });
    };
    form.addEventListener('change', function () { clearTimeout(timer); timer = setTimeout(save, 600); });
    form.addEventListener('input', function (ev) {
      if (ev.target.tagName === 'TEXTAREA' || ev.target.type === 'text') { clearTimeout(timer); timer = setTimeout(save, 1500); }
    });
  }
})();
