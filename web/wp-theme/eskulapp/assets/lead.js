// Eskulapp, wysylka formularza zapytania ofertowego do /api/lead (mail: kontakt@eskulapp.pl)
(function () {
  var form = document.getElementById('lead-form');
  if (!form) return;
  var api = (document.querySelector('meta[name="eskulapp-api"]') || {}).content || '/api';
  var errBox = document.getElementById('lead-error');
  var okBox = document.getElementById('lead-ok');

  form.addEventListener('submit', function (ev) {
    ev.preventDefault();
    errBox.style.display = 'none';
    var name = form.name.value.trim();
    var email = form.email.value.trim();
    if (!name || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      errBox.textContent = 'Podaj imię i poprawny e-mail.';
      errBox.style.display = 'block';
      return;
    }
    var btn = form.querySelector('button[type="submit"]');
    btn.disabled = true; btn.textContent = 'Wysyłanie...';
    var body = new URLSearchParams({
      name: name, email: email,
      org: form.org.value.trim(),
      message: form.message.value.trim(),
      website: form.website.value
    });
    fetch(api + '/lead', { method: 'POST', headers: { 'Content-Type': 'application/x-www-form-urlencoded' }, body: body })
      .then(function (r) { return r.json().catch(function () { return { ok: r.ok }; }); })
      .then(function (d) {
        if (d && d.ok) { form.style.display = 'none'; okBox.style.display = 'block'; }
        else { throw new Error('fail'); }
      })
      .catch(function () {
        errBox.textContent = 'Coś poszło nie tak. Napisz na kontakt@eskulapp.pl';
        errBox.style.display = 'block';
        btn.disabled = false; btn.textContent = 'Wyślij zapytanie';
      });
  });
})();
