import { serve } from 'std/server';
import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = Deno.env.get('SUPABASE_URL')!;
const SUPABASE_KEY = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
const SENDGRID_API_KEY = Deno.env.get('SENDGRID_API_KEY')!;
const SENDER_EMAIL = Deno.env.get('SENDER_EMAIL') || 'no-reply@example.com';
const TARGET_EMAILS = (Deno.env.get('TARGET_EMAILS') || 'asvgrossostheimjugend@gmail.com,reid15_halo@yahoo.de,erwinglawion@aol.com').split(',');

const supa = createClient(SUPABASE_URL, SUPABASE_KEY, { auth: { persistSession: false } });

// helper: escape CSV cell
function escapeCell(s: string) {
  if (s.includes(',') || s.includes('"') || s.includes('\n')) return '"' + s.replace(/"/g, '""') + '"';
  return s;
}

serve(async (req) => {
  try {
    // Authorization: either a pre-shared secret header (X-EXPORT-SECRET) for CI
    // or an Authorization: Bearer <token> header where the user's claims include is_admin=true.
    const secretHeader = req.headers.get('x-export-secret') || '';
    const expected = Deno.env.get('EXPORT_EDGE_SECRET') || '';
    let authorized = false;
    if (expected && secretHeader === expected) {
      authorized = true;
    } else {
      // try Bearer token
      const auth = req.headers.get('authorization') || '';
      if (auth.startsWith('Bearer ')) {
        const token = auth.substring(7);
        const { data: user, error } = await supa.auth.getUser(token);
        if (!error && user && user.user) {
          const claims = (user.user.user_metadata || {}) as any;
          if (claims.is_admin) authorized = true;
        }
      }
    }
    if (!authorized) return new Response('Forbidden', { status: 403 });

    const body = await req.json().catch(() => ({}));
    const year = body.year || new Date().getFullYear();

    // Fetch members
    const { data: members } = await supa.from('member').select('id,user_id,display_name');

    // Define CSV header (ISO dates): captured_at, member_id, member_display_name, species_id, species_name, length_cm, weight_g, water_body_id, water_name, photo_url, privacy_level
    const headers = ['captured_at','member_id','member_display_name','species_id','species_name','length_cm','weight_g','water_body_id','water_name','photo_url','privacy_level'];
    const rows: string[] = [];
    rows.push(headers.join(','));

    for (const m of (members || [])) {
      const memberId = m.id;
      const key = `users/${memberId}/catches-${year}.json`;
      try {
        const { data: bytes, error } = await supa.storage.from('catch_photos').download(key);
        if (error || !bytes) continue;
        const content = new TextDecoder().decode(bytes as Uint8Array);
        const list = JSON.parse(content);
        for (const item of list) {
          const captured = item.captured_at ? new Date(item.captured_at).toISOString() : '';
          const member_display_name = m.display_name || '';
          const row = [captured, String(memberId), member_display_name, String(item.species_id ?? ''), String(item.species_name ?? item.species_id ?? ''), String(item.length_cm ?? ''), String(item.weight_g ?? ''), String(item.water_body_id ?? ''), String(item.water_name ?? item.water_body_id ?? ''), String(item.photo_url ?? ''), String(item.privacy_level ?? '')];
          rows.push(row.map(c => escapeCell(c)).join(','));
        }
      } catch (e) {
        // ignore per-member failures
        console.error('member read error', memberId, e);
      }
    }

    const csvContent = rows.join('\n');

    // Send via SendGrid REST API
    const mail = {
      personalizations: [{ to: TARGET_EMAILS.map(t => ({ email: t })), subject: `ASV Fangbücher Export ${year}` }],
      from: { email: SENDER_EMAIL },
      content: [{ type: 'text/plain', value: `Im Anhang: Export der Fangbücher für ${year}` }],
      attachments: [{ content: btoa(csvContent), filename: `asv_catches_${year}.csv`, type: 'text/csv', disposition: 'attachment' }]
    };

    const res = await fetch('https://api.sendgrid.com/v3/mail/send', {
      method: 'POST',
      headers: { 'Authorization': `Bearer ${SENDGRID_API_KEY}`, 'Content-Type': 'application/json' },
      body: JSON.stringify(mail)
    });

    if (!res.ok) {
      const text = await res.text();
      console.error('sendgrid error', res.status, text);
      return new Response('Email send failed', { status: 500 });
    }

    return new Response(JSON.stringify({ ok: true, year }), { status: 200, headers: { 'Content-Type': 'application/json' } });
  } catch (e) {
    console.error(e);
    return new Response(String(e), { status: 500 });
  }
});
