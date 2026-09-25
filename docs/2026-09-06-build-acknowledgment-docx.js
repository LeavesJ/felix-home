const { Document, Packer, Paragraph, TextRun, AlignmentType } = require('docx');
const fs = require('fs');

const LETTER = { size: { width: 12240, height: 15840 }, margin: { top: 1440, right: 1440, bottom: 1440, left: 1440 } };
const FONT = 'Calibri';

function p(runs, opts = {}) {
  return new Paragraph({
    spacing: { after: opts.after === undefined ? 180 : opts.after, line: 276 },
    alignment: opts.align,
    children: Array.isArray(runs) ? runs : [runs],
  });
}
function t(text, opts = {}) {
  return new TextRun({ text, bold: !!opts.b, italics: !!opts.i, font: FONT, size: opts.size || 22 });
}
function clause(lead, body, opts = {}) {
  return p([t(lead, { b: true }), t(' ' + body)], opts);
}
function title(text) {
  return new Paragraph({
    spacing: { after: 320 },
    alignment: AlignmentType.CENTER,
    children: [t(text, { b: true, size: 26 })],
  });
}

const letter = [
  title('FELIX AND BETA CONFIDENTIALITY ACKNOWLEDGMENT'),

  p([
    t('This acknowledgment is made on '), t('September 6, 2026', { b: true }),
    t(' by '), t('Riyan Jain', { b: true }), t(', a founder of '),
    t('Elenchus Labs, Inc.', { b: true }),
    t(' ("the Company"), in connection with his access to the systems and material described below.'),
  ], { after: 320 }),

  clause('1. Felix.',
    'Riyan will be given read access to the private repository at github.com/LeavesJ/felix ("Felix"), which governs engineering practice across more than one venture, not only the Company. Riyan will keep Felix’s contents confidential, use them only to develop and operate the Company’s Elenchus product, and not disclose them to any third party, regardless of whether Felix’s contents are covered by any other confidentiality obligation Riyan holds to the Company. This obligation survives for as long as Riyan retains access to Felix and does not depend on his status as a founder, employee, or in any other capacity.'),

  clause('2. Beta and personal data.',
    'The Company operates a closed beta of Elenchus in which invited individuals have written personal material. Riyan is not granted access to invitee databases, server logs, Cloudflare Access policies, or any other record of invitee activity, and will not seek or retain access to them. If Riyan encounters such data incidentally, he will not copy it, will not use it, and will tell Jarron Wan Deng promptly. Any future change to this section requires a separate written agreement between Riyan and Jarron Wan Deng.'),

  clause('3. Credentials.',
    'Riyan will use only credentials issued to him, will not share them, and will not use Jarron Wan Deng’s personal credentials. Riyan will not commit any credential, key, or personal data to any repository.',
    { after: 400 }),

  p(t('Agreed:', { b: true }), { after: 480 }),
  p(t('Riyan Jain  ______________________________    Date: __________')),
];

function build(children) {
  return new Document({
    styles: { default: { document: { run: { font: FONT, size: 22 } } } },
    sections: [{ properties: { page: LETTER }, children }],
  });
}

(async () => {
  const out = '/tmp/claude-0/-home-user/a9ac27e2-0ea1-5700-b5ed-e6f8abae7ff7/scratchpad/';
  fs.writeFileSync(out + 'Felix-Beta-Confidentiality-Acknowledgment.docx', await Packer.toBuffer(build(letter)));
  console.log('built');
})();
