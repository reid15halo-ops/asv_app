const { createClient } = require('@supabase/supabase-js');
const fs = require('fs');
const os = require('os');
const path = require('path');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SUPABASE_URL || !SUPABASE_KEY) throw new Error('Set SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY');

// CLI flags
const DRY_RUN = process.env.DRY_RUN === '1' || process.argv.includes('--dry-run');
const BATCH_SIZE = parseInt(process.env.BATCH_SIZE || process.argv.find(a => a.startsWith('--batch='))?.split('=')[1] || '20', 10);
const PAUSE_MS = parseInt(process.env.PAUSE_MS || '200', 10);

const supa = createClient(SUPABASE_URL, SUPABASE_KEY, { auth: { persistSession: false } });

async function run() {
  console.log('Fetching catches from DB...');
  const { data: catches, error } = await supa.from('catch').select('*');
  if (error) throw error;
  console.log(`Found ${catches.length} catches`);

  // group by member_id and year
  const groups = {};
  for (const c of catches) {
    const memberId = c.member_id || 'unknown';
    const year = c.captured_at ? new Date(c.captured_at).getFullYear() : new Date().getFullYear();
    const key = `${memberId}:${year}`;
    groups[key] = groups[key] || [];
    groups[key].push(c);
  }

  const keys = Object.keys(groups);
  console.log(`About to process ${keys.length} member-year groups in batches of ${BATCH_SIZE} (dry-run=${DRY_RUN})`);

  for (let i = 0; i < keys.length; i += BATCH_SIZE) {
    const batch = keys.slice(i, i + BATCH_SIZE);
    for (const k of batch) {
      const [memberId, year] = k.split(':');
      const storageKey = `users/${memberId}/catches-${year}.json`;
      console.log('Processing', storageKey, 'items', groups[k].length);

      // try to download existing
      let existing = [];
      try {
        const { data: bytes, error: dlErr } = await supa.storage.from('catch_photos').download(storageKey);
        if (!dlErr && bytes) existing = JSON.parse(Buffer.from(bytes).toString('utf8'));
      } catch (e) {
        // ignore
      }

      // merge with deduplication by 'id'
      const map = new Map();
      for (const e of existing) if (e && e.id != null) map.set(String(e.id), e);
      for (const n of groups[k]) if (n && n.id != null) map.set(String(n.id), n);
      // include any items without id by appending
      const noId = [];
      for (const e of existing.concat(groups[k])) if (e && e.id == null) noId.push(e);

      const merged = Array.from(map.values()).concat(noId);

      if (DRY_RUN) {
        console.log(`[dry-run] would write ${merged.length} items to ${storageKey}`);
        continue;
      }

      // write to temp file then upload
      const tmpPath = path.join(os.tmpdir(), `asv_mig_${memberId}_${year}_${Date.now()}.json`);
      fs.writeFileSync(tmpPath, JSON.stringify(merged));
      try {
        await supa.storage.from('catch_photos').upload(storageKey, fs.createReadStream(tmpPath), { upsert: true });
        console.log('Uploaded', storageKey, 'items:', merged.length);
      } catch (e) {
        console.error('Upload failed for', storageKey, e);
      } finally {
        try { fs.unlinkSync(tmpPath); } catch (_) {}
      }
    }
    // pause between batches
    if (i + BATCH_SIZE < keys.length) {
      console.log(`Batch ${i / BATCH_SIZE + 1} done — sleeping ${PAUSE_MS}ms before next batch`);
      await new Promise(r => setTimeout(r, PAUSE_MS));
    }
  }

  console.log('Migration complete');
}

run().catch(err => { console.error(err); process.exit(1); });
