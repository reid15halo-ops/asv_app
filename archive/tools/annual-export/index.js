const { createClient } = require('@supabase/supabase-js');
const sgMail = require('@sendgrid/mail');
const AdmZip = require('adm-zip');
const fs = require('fs');
const path = require('path');
const ExcelJS = require('exceljs');

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY; // service role required for storage read
const SENDGRID_KEY = process.env.SENDGRID_API_KEY;
const SENDER_EMAIL = process.env.SENDER_EMAIL || 'no-reply@example.com';
const TARGET_EMAILS = (process.env.TARGET_EMAILS || 'asvgrossostheimjugend@gmail.com,reid15_halo@yahoo.de,erwinglawion@aol.com').split(',');
const YEAR = process.env.EXPORT_YEAR || (new Date().getFullYear());

if (!SUPABASE_URL || !SUPABASE_KEY) throw new Error('Missing Supabase env vars');
if (!SENDGRID_KEY) throw new Error('Missing SendGrid API key');

sgMail.setApiKey(SENDGRID_KEY);
const supa = createClient(SUPABASE_URL, SUPABASE_KEY, { auth: { persistSession: false } });

async function run() {
  console.log('Starting annual export for year', YEAR);
  // fetch all members/users
  const { data: users } = await supa.from('member').select('id,user_id,display_name');
  const zip = new AdmZip();

  for (const u of users || []) {
    const userId = u.user_id;
    const memberId = u.id;
    const remoteKey = `users/${memberId}/catches-${YEAR}.json`;
    try {
      const { data: fileBytes, error } = await supa.storage.from('catch_photos').download(remoteKey);
      if (error || !fileBytes) {
        console.log('No data for', memberId);
        continue;
      }
      const content = Buffer.from(fileBytes).toString('utf8');
      const arr = JSON.parse(content);
      // convert to XLSX
      const workbook = new ExcelJS.Workbook();
      const sheet = workbook.addWorksheet('Catches');
      const keys = new Set();
      for (const it of arr) Object.keys(it).forEach(k => keys.add(k));
      const header = Array.from(keys);
      sheet.addRow(header);
      for (const it of arr) {
        const row = header.map(k => (it[k] === undefined || it[k] === null) ? '' : it[k]);
        sheet.addRow(row);
      }
      const buf = await workbook.xlsx.writeBuffer();
      const filename = `member_${memberId}_catches_${YEAR}.xlsx`;
      zip.addFile(filename, Buffer.from(buf));
    } catch (e) {
      console.error('Error processing', remoteKey, e);
    }
  }

  const outName = `asv_catches_${YEAR}.zip`;
  const outPath = path.join(process.cwd(), outName);
  zip.writeZip(outPath);

  // send email with attachment
  const mail = {
    to: TARGET_EMAILS,
    from: SENDER_EMAIL,
    subject: `ASV Fangbücher Export ${YEAR}`,
    text: `Im Anhang: Export der Fangbücher für ${YEAR}`,
    attachments: [
      {
        content: fs.readFileSync(outPath).toString('base64'),
        filename: outName,
        type: 'application/zip',
        disposition: 'attachment'
      }
    ]
  };

  await sgMail.send(mail);
  console.log('Email sent to', TARGET_EMAILS.join(', '));
}

run().catch(err => { console.error(err); process.exit(1); });
