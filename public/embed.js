(() => {
  'use strict';
  const endpoint = 'https://forms.osnova-mind.ru/v1/intake';
  const key = 'osnova.intake.pending.v1';
  let pending;
  const utmKeys = ['utm_source','utm_medium','utm_campaign','utm_content','utm_term'];
  function tracking() {
    const current = Object.fromEntries(utmKeys.map(k => [k, new URL(location.href).searchParams.get(k) || '']));
    try {
      const first = JSON.parse(sessionStorage.getItem('osnova.utm.v1') || 'null');
      if (first) return first;
      sessionStorage.setItem('osnova.utm.v1', JSON.stringify(current));
    } catch {}
    return current;
  }
  const utm = tracking();
  window.OsnovaIntake = {
    async submit(data) {
      const fingerprint = JSON.stringify(data);
      if (!pending) { try { pending = JSON.parse(sessionStorage.getItem(key)); } catch {} }
      if (!pending || pending.fingerprint !== fingerprint) {
        pending = {fingerprint, body: {...data, version:1, form:'diagnostic-intake', website:document.querySelector('[data-osnova-honeypot]')?.value || '', client_submission_id:crypto.randomUUID(), page:location.href, referrer:document.referrer, utm}};
        try { sessionStorage.setItem(key, JSON.stringify(pending)); } catch {}
      }
      const response = await fetch(endpoint, {method:'POST', headers:{'Content-Type':'application/json'}, body:JSON.stringify(pending.body), credentials:'omit', signal:AbortSignal.timeout(20000)});
      if (!response.ok) throw new Error('submission_failed');
      const result = await response.json();
      if (result.ok !== true) throw new Error('submission_failed');
      pending = null;
      try { sessionStorage.removeItem(key); } catch {}
      return result;
    }
  };
})();
