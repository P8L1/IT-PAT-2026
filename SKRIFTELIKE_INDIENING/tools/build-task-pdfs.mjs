import crypto from 'node:crypto';
import fs from 'node:fs';
import fsp from 'node:fs/promises';
import path from 'node:path';
import process from 'node:process';
import { spawnSync } from 'node:child_process';
import { fileURLToPath, pathToFileURL } from 'node:url';

import hljs from 'highlight.js';
import katex from 'katex';
import MarkdownIt from 'markdown-it';
import markdownItAnchor from 'markdown-it-anchor';
import markdownItDeflist from 'markdown-it-deflist';
import markdownItFootnote from 'markdown-it-footnote';
import markdownItTaskLists from 'markdown-it-task-lists';
import markdownItTexmath from 'markdown-it-texmath';
import { chromium } from 'playwright-core';

const scriptDirectory = path.dirname(fileURLToPath(import.meta.url));
const workspaceRoot = path.resolve(scriptDirectory, '..');
const outputRoot = path.join(workspaceRoot, 'PDF_UITVOER');
const tempRoot = path.join(workspaceRoot, 'tmp', 'pdfs');
const htmlRoot = path.join(tempRoot, 'html');
const renderRoot = path.join(tempRoot, 'rendered');
const validationPath = path.join(tempRoot, 'validation.json');
const manifestPath = path.join(tempRoot, 'build-manifest.json');

const taskDefinitions = [1, 2, 3, 4, 5].map((number) => ({
  number,
  id: `TAAK${number}`,
  folderPattern: new RegExp(`^taak[_ -]?${number}$`, 'i'),
}));

const imageExtensions = new Set(['.png', '.jpg', '.jpeg', '.gif', '.webp', '.svg', '.bmp']);
const externalProtocols = new Set(['http:', 'https:', 'mailto:']);
const unsafeProtocols = new Set(['javascript:', 'data:', 'vbscript:']);

function assertGeneratedPath(target) {
  const resolved = path.resolve(target);
  const allowedRoots = [path.resolve(outputRoot), path.resolve(tempRoot)];
  if (!allowedRoots.some((root) => resolved === root || resolved.startsWith(`${root}${path.sep}`))) {
    throw new Error(`Refusing to modify a path outside generated output: ${resolved}`);
  }
  return resolved;
}

async function resetDirectory(target) {
  const safeTarget = assertGeneratedPath(target);
  await fsp.rm(safeTarget, { recursive: true, force: true });
  await fsp.mkdir(safeTarget, { recursive: true });
}

function escapeHtml(value) {
  return String(value)
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&#39;');
}

function sha256(value) {
  return crypto.createHash('sha256').update(value).digest('hex');
}

function slugify(value) {
  const slug = String(value)
    .normalize('NFKD')
    .replace(/[\u0300-\u036f]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '');
  return slug || 'afdeling';
}

function safeFilename(filename) {
  const parsed = path.parse(filename);
  const safeBase = parsed.name
    .replace(/[<>:"/\\|?*\u0000-\u001f]/g, '-')
    .replace(/\s+/g, ' ')
    .replace(/[. ]+$/g, '')
    .trim() || 'gekoppelde-leer';
  const safeExtension = parsed.ext.replace(/[<>:"/\\|?*\u0000-\u001f]/g, '');
  return `${safeBase}${safeExtension}`;
}

async function listFilesRecursive(directory) {
  const output = [];
  for (const entry of await fsp.readdir(directory, { withFileTypes: true })) {
    const fullPath = path.join(directory, entry.name);
    if (entry.isDirectory()) {
      output.push(...await listFilesRecursive(fullPath));
    } else if (entry.isFile()) {
      output.push(fullPath);
    }
  }
  return output;
}

async function locateTasks() {
  const rootEntries = await fsp.readdir(workspaceRoot, { withFileTypes: true });
  const tasks = [];
  for (const definition of taskDefinitions) {
    const folderEntry = rootEntries.find((entry) => entry.isDirectory() && definition.folderPattern.test(entry.name));
    if (!folderEntry) {
      throw new Error(`Could not locate the source folder for ${definition.id}.`);
    }
    const folder = path.join(workspaceRoot, folderEntry.name);
    const markdownFiles = (await fsp.readdir(folder, { withFileTypes: true }))
      .filter((entry) => entry.isFile() && path.extname(entry.name).toLowerCase() === '.md')
      .map((entry) => path.join(folder, entry.name));
    if (markdownFiles.length === 0) {
      throw new Error(`${definition.id} contains no Markdown file.`);
    }
    const scored = [];
    for (const candidate of markdownFiles) {
      const text = await fsp.readFile(candidate, 'utf8');
      const filename = path.basename(candidate).toLowerCase();
      const firstHeading = text.match(/^#\s+(.+)$/m)?.[1]?.trim() ?? '';
      let score = 0;
      if (filename.startsWith(`taak_${definition.number}`) || filename.startsWith(`taak${definition.number}`)) score += 10;
      if (new RegExp(`^taak\s+${definition.number}\b`, 'i').test(firstHeading)) score += 8;
      if (filename.includes('notas') || filename.includes('readme')) score -= 4;
      scored.push({ candidate, text, firstHeading, score });
    }
    scored.sort((left, right) => right.score - left.score || left.candidate.localeCompare(right.candidate));
    if (scored.length > 1 && scored[0].score === scored[1].score) {
      throw new Error(`The primary Markdown file for ${definition.id} is ambiguous.`);
    }
    const selected = scored[0];
    tasks.push({
      ...definition,
      folder,
      folderName: folderEntry.name,
      sourcePath: selected.candidate,
      sourceRelative: path.relative(workspaceRoot, selected.candidate),
      sourceText: selected.text,
      sourceHashBefore: sha256(selected.text),
      title: selected.firstHeading || definition.id,
      selectionDecision: markdownFiles.length === 1
        ? 'The folder contains exactly one Markdown file.'
        : `Selected the highest-scoring task filename and first heading from ${markdownFiles.length} candidates.`,
    });
  }
  return tasks;
}

function inspectMarkdown(source) {
  const links = [...source.matchAll(/!?\[([^\]]*)\]\(([^)]+)\)/g)];
  return {
    headings: (source.match(/^#{1,6}\s+/gm) ?? []).length,
    tables: (source.match(/^\|.*\|\s*$/gm) ?? []).length > 1,
    orderedLists: /^\s*\d+[.)]\s+/m.test(source),
    unorderedLists: /^\s*[-+*]\s+/m.test(source),
    blockquotes: /^>\s?/m.test(source),
    fencedCode: /^```/m.test(source),
    inlineCode: /`[^`\n]+`/.test(source),
    images: links.filter((match) => match[0].startsWith('!')).length,
    math: /(^|[^\\])\$[^$\n]+\$|\\\(|\\\[/.test(source),
    internalLinks: links.filter((match) => match[2].trim().startsWith('#')).length,
    externalLinks: links.filter((match) => /^(https?:|mailto:)/i.test(match[2].trim())).length,
    localLinks: links.filter((match) => !match[0].startsWith('!') && !/^(#|https?:|mailto:)/i.test(match[2].trim())).length,
    footnotes: /\[\^[^\]]+\]/.test(source),
    definitionLists: /^:\s+/m.test(source),
    taskLists: /^\s*[-+*]\s+\[[ xX]\]\s+/m.test(source),
    inlineHtml: /<\/?(?:a|abbr|address|article|aside|b|blockquote|br|code|div|em|figure|figcaption|footer|h[1-6]|header|hr|i|img|li|main|nav|ol|p|pre|section|small|span|strong|sub|sup|table|tbody|td|th|thead|tr|ul)(?:\s|\/?>)/i.test(source),
    nonAsciiPaths: links.some((match) => /[^\x00-\x7f]/.test(match[2])),
    pathsWithSpaces: links.some((match) => /\s/.test(match[2])),
    absoluteLocalPaths: links.some((match) => /^[a-z]:[\\/]/i.test(match[2].trim())),
  };
}

async function resolveLocalTarget(rawHref, task, allTaskFiles) {
  const withoutFragment = rawHref.split('#', 1)[0].split('?', 1)[0];
  let decoded = withoutFragment;
  try {
    decoded = decodeURIComponent(withoutFragment);
  } catch {
    // Preserve the original text and try the undecoded path.
  }
  const normalized = decoded.replace(/[\\/]+/g, path.sep);
  const exact = path.isAbsolute(normalized)
    ? path.normalize(normalized)
    : path.resolve(path.dirname(task.sourcePath), normalized);
  try {
    if ((await fsp.stat(exact)).isFile()) {
      return { path: exact, corrected: false, reason: 'Resolved relative to the containing Markdown file.' };
    }
  } catch {
    // Continue to the bounded task-folder recovery rules below.
  }

  const referencedBase = path.win32.basename(decoded.replaceAll('/', '\\')).toLowerCase();
  const exactNameMatches = allTaskFiles.filter((candidate) => path.basename(candidate).toLowerCase() === referencedBase);
  if (exactNameMatches.length === 1) {
    return {
      path: exactNameMatches[0],
      corrected: true,
      reason: 'The source-relative path was missing; recovered the only same-named file inside the task folder.',
    };
  }

  const referencedParent = path.win32.basename(path.win32.dirname(decoded.replaceAll('/', '\\'))).toLowerCase();
  const referencedExtension = path.extname(referencedBase).toLowerCase();
  const folderAndTypeMatches = allTaskFiles.filter((candidate) =>
    path.basename(path.dirname(candidate)).toLowerCase() === referencedParent
      && path.extname(candidate).toLowerCase() === referencedExtension);
  if (folderAndTypeMatches.length === 1) {
    return {
      path: folderAndTypeMatches[0],
      corrected: true,
      reason: 'The source filename was missing; recovered the only file of the requested type in the named task subfolder.',
    };
  }

  return { path: null, corrected: false, reason: 'No unique target could be resolved inside the task folder.' };
}

function classifyHref(href) {
  if (href.startsWith('#')) return 'internal';
  const protocolMatch = href.match(/^([a-z][a-z0-9+.-]*:)/i);
  if (!protocolMatch) return 'local';
  const protocol = protocolMatch[1].toLowerCase();
  if (externalProtocols.has(protocol)) return 'external';
  if (/^[a-z]:$/i.test(protocol.slice(0, -1))) return 'local';
  if (unsafeProtocols.has(protocol)) return 'unsafe';
  return 'unsupported';
}

function tokenText(tokens, startIndex) {
  const parts = [];
  for (let index = startIndex + 1; index < tokens.length && tokens[index].type !== 'link_close'; index += 1) {
    const token = tokens[index];
    if (token.type === 'text' || token.type === 'code_inline') parts.push(token.content);
    if (token.type === 'image') parts.push(token.content);
  }
  return parts.join(' ').trim() || 'Gekoppelde lêer';
}

async function processTokenList(tokens, context) {
  for (let index = 0; index < tokens.length; index += 1) {
    const token = tokens[index];
    if (token.children) await processTokenList(token.children, context);

    if (token.type === 'link_open') {
      const href = token.attrGet('href') ?? '';
      const kind = classifyHref(href);
      const label = tokenText(tokens, index);
      if (kind === 'external') {
        context.externalLinks.push(href);
        token.attrSet('rel', 'noopener noreferrer');
      } else if (kind === 'internal') {
        context.internalLinks.push(href);
      } else if (kind === 'local') {
        let displayHref = href;
        try {
          displayHref = decodeURIComponent(href);
        } catch {
          // Keep the parser-normalized href if it is not valid percent encoding.
        }
        const resolution = await resolveLocalTarget(href, context.task, context.taskFiles);
        if (!resolution.path) {
          context.unresolvedLinks.push({ label, href: displayHref, reason: resolution.reason });
          token.attrSet('href', `#onbeskikbaar-${context.unresolvedLinks.length}`);
          token.attrJoin('class', ' broken-link');
          token.attrSet('title', `Onbeskikbaar: ${href}`);
          continue;
        }
        let bundled = context.copiedBySource.get(resolution.path.toLowerCase());
        if (!bundled) {
          const originalName = safeFilename(path.basename(resolution.path));
          const parsed = path.parse(originalName);
          let candidateName = originalName;
          let suffix = 2;
          while (context.usedBundleNames.has(candidateName.toLowerCase())) {
            candidateName = `${parsed.name}-${suffix}${parsed.ext}`;
            suffix += 1;
          }
          context.usedBundleNames.add(candidateName.toLowerCase());
          const destination = path.join(context.bundleDirectory, candidateName);
          await fsp.copyFile(resolution.path, destination);
          bundled = {
            destination,
            filename: candidateName,
            bundleRelative: path.posix.join('gekoppelde_leers', context.task.id, candidateName),
          };
          context.copiedBySource.set(resolution.path.toLowerCase(), bundled);
        }
        const localRecord = {
          label,
          originalHref: displayHref,
          sourcePath: resolution.path,
          sourceRelative: path.relative(workspaceRoot, resolution.path),
          corrected: resolution.corrected,
          correctionReason: resolution.reason,
          destination: bundled.destination,
          bundleRelative: bundled.bundleRelative,
          pdfHref: pathToFileURL(bundled.destination).href,
        };
        context.localLinks.push(localRecord);
        token.attrSet('href', localRecord.pdfHref);
        token.attrSet('title', `Gebundel as ${localRecord.bundleRelative}`);
      } else {
        context.unresolvedLinks.push({ label, href, reason: `Unsafe or unsupported protocol (${kind}).` });
        token.attrSet('href', `#onbeskikbaar-${context.unresolvedLinks.length}`);
        token.attrJoin('class', ' broken-link');
      }
    }

    if (token.type === 'image') {
      const src = token.attrGet('src') ?? '';
      const kind = classifyHref(src);
      if (kind !== 'local') {
        context.missingImages.push({ label: token.content, href: src, reason: 'Remote or unsafe images are not loaded.' });
        token.attrSet('src', transparentPixel);
        token.attrJoin('class', ' missing-image');
        continue;
      }
      const resolution = await resolveLocalTarget(src, context.task, context.taskFiles);
      if (!resolution.path) {
        context.missingImages.push({ label: token.content, href: src, reason: resolution.reason });
        token.attrSet('src', transparentPixel);
        token.attrJoin('class', ' missing-image');
        continue;
      }
      const extension = path.extname(resolution.path).toLowerCase();
      if (!imageExtensions.has(extension)) {
        context.missingImages.push({ label: token.content, href: src, reason: 'The resolved target is not a supported image type.' });
        token.attrSet('src', transparentPixel);
        token.attrJoin('class', ' missing-image');
        continue;
      }
      const mime = extension === '.svg' ? 'image/svg+xml'
        : extension === '.jpg' || extension === '.jpeg' ? 'image/jpeg'
          : extension === '.png' ? 'image/png'
            : extension === '.gif' ? 'image/gif'
              : extension === '.webp' ? 'image/webp' : 'image/bmp';
      const data = await fsp.readFile(resolution.path);
      token.attrSet('src', `data:${mime};base64,${data.toString('base64')}`);
      token.attrSet('alt', token.content || path.basename(resolution.path));
      context.images.push({
        originalHref: src,
        sourcePath: resolution.path,
        sourceRelative: path.relative(workspaceRoot, resolution.path),
        corrected: resolution.corrected,
        correctionReason: resolution.reason,
      });
    }
  }
}

const transparentPixel = 'data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=';

function createMarkdownRenderer() {
  return new MarkdownIt({
    html: false,
    linkify: true,
    typographer: false,
    breaks: false,
    highlight(code, language) {
      if (language && hljs.getLanguage(language)) {
        return `<pre class="hljs"><code>${hljs.highlight(code, { language, ignoreIllegals: true }).value}</code></pre>`;
      }
      return `<pre class="hljs"><code>${escapeHtml(code)}</code></pre>`;
    },
  })
    .use(markdownItAnchor, { slugify, permalink: false })
    .use(markdownItFootnote)
    .use(markdownItDeflist)
    .use(markdownItTaskLists, { enabled: true, label: true, labelAfter: true })
    .use(markdownItTexmath, {
      engine: katex,
      delimiters: 'dollars',
      katexOptions: { output: 'mathml', throwOnError: false, strict: 'warn' },
    });
}

function linkedFilesSection(context) {
  if (context.localLinks.length === 0) return '';
  const rows = context.localLinks.map((link) => `
    <tr>
      <td><a href="${escapeHtml(link.pdfHref)}">${escapeHtml(link.label)}</a></td>
      <td><code>${escapeHtml(link.bundleRelative)}</code></td>
      <td><code>${escapeHtml(link.sourceRelative)}</code></td>
      <td>Ja - 'n PDF-skakelannotasie word versoek; plaaslike opening bly kyker-afhanklik.</td>
    </tr>`).join('');
  return `
    <section class="linked-files-section">
      <h2 id="gekoppelde-leers">Gekoppelde lêers</h2>
      <p>Die lêers hieronder is saam met die PDF-bundel gekopieer. Gebruik die sigbare bundelpad indien 'n PDF-leser plaaslike skakels blokkeer.</p>
      <table>
        <thead><tr><th>Oorspronklike skakeletiket</th><th>Gebundelde relatiewe pad</th><th>Bronpad</th><th>PDF-skakelstatus</th></tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </section>`;
}

function missingItemsSection(context) {
  const items = [
    ...context.unresolvedLinks.map((item) => `Onopgeloste skakel: ${item.label} (${item.href})`),
    ...context.missingImages.map((item) => `Ontbrekende beeld: ${item.label || item.href} (${item.href})`),
  ];
  if (items.length === 0) return '';
  return `
    <section class="unavailable-section">
      <h2 id="onbeskikbare-bronne">Onbeskikbare bronne</h2>
      <ul>${items.map((item) => `<li>${escapeHtml(item)}</li>`).join('')}</ul>
    </section>`;
}

function themePalette(theme) {
  if (theme === 'dark') {
    return {
      page: '#222222', surface: '#2b2b2b', raised: '#303030', text: '#e8e8e8',
      secondary: '#b8b8b8', border: '#4a4a4a', link: '#82b4ff', code: '#1f1f1f',
      heading: '#f0f0f0', accent: '#8fb8e8', quote: '#303030', danger: '#ffb4ab',
    };
  }
  return {
    page: '#ffffff', surface: '#f5f7f9', raised: '#edf1f4', text: '#20252b',
    secondary: '#5d6772', border: '#cbd2d9', link: '#185fa7', code: '#f2f4f6',
    heading: '#17212b', accent: '#2e6f9e', quote: '#f4f7fa', danger: '#9c2f25',
  };
}

function stylesheet(theme) {
  const p = themePalette(theme);
  return `
    :root {
      --page-bg: ${p.page}; --surface-bg: ${p.surface}; --surface-raised: ${p.raised};
      --text-primary: ${p.text}; --text-secondary: ${p.secondary}; --border: ${p.border};
      --link: ${p.link}; --code-bg: ${p.code}; --heading: ${p.heading};
      --accent: ${p.accent}; --quote-bg: ${p.quote}; --danger: ${p.danger};
    }
    @page { size: A4; margin: 18mm 14mm 16mm 14mm; background: var(--page-bg); }
    * { box-sizing: border-box; }
    html, body { margin: 0; padding: 0; background: var(--page-bg); color: var(--text-primary); }
    html { font-family: "Segoe UI", Arial, Helvetica, sans-serif; font-size: 10.2pt; }
    body { line-height: 1.48; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
    main.document { width: 100%; max-width: 182mm; margin: 0 auto; }
    .task-kicker { color: var(--accent); font-size: 7.5pt; font-weight: 700; letter-spacing: .13em; text-transform: uppercase; margin: 0 0 3mm; }
    h1, h2, h3, h4, h5, h6 { color: var(--heading); line-height: 1.2; break-after: avoid; page-break-after: avoid; }
    h1 { font-size: 23pt; letter-spacing: -.025em; margin: 0 0 8mm; padding-bottom: 4mm; border-bottom: 1.2pt solid var(--border); }
    h2 { font-size: 15.5pt; margin: 9mm 0 3.5mm; padding-bottom: 1.7mm; border-bottom: .7pt solid var(--border); }
    h3 { font-size: 12.2pt; margin: 6.5mm 0 2.5mm; }
    h4 { font-size: 10.8pt; margin: 5mm 0 2mm; }
    p { margin: 0 0 3.2mm; orphans: 3; widows: 3; }
    ul, ol { margin: 0 0 3.8mm; padding-left: 6mm; }
    li { margin: 0 0 1.2mm; }
    li > p { margin-bottom: 1.2mm; }
    a { color: var(--link); text-decoration: underline; text-decoration-thickness: .7pt; text-underline-offset: 1.5pt; overflow-wrap: anywhere; }
    a:visited { color: var(--link); }
    .broken-link { color: var(--danger); text-decoration-style: wavy; }
    blockquote { margin: 4.5mm 0; padding: 3.5mm 4.5mm; background: var(--quote-bg); border-left: 3pt solid var(--accent); color: var(--text-primary); break-inside: avoid; }
    blockquote > :last-child { margin-bottom: 0; }
    code, kbd, samp { font-family: Consolas, "Cascadia Mono", "Courier New", monospace; font-size: .88em; }
    :not(pre) > code { background: var(--surface-raised); border: .5pt solid var(--border); border-radius: 2.5pt; padding: .08em .3em; overflow-wrap: anywhere; }
    pre { margin: 4mm 0; padding: 3.5mm 4mm; background: var(--code-bg); border: .6pt solid var(--border); border-radius: 3pt; white-space: pre-wrap; overflow-wrap: anywhere; word-break: break-word; line-height: 1.42; break-inside: avoid; }
    pre code { font-size: 8.3pt; }
    .hljs-keyword, .hljs-selector-tag, .hljs-literal { color: ${theme === 'dark' ? '#c8a7ff' : '#7b2cbf'}; }
    .hljs-string, .hljs-title, .hljs-section { color: ${theme === 'dark' ? '#a8d8a2' : '#2f7d32'}; }
    .hljs-number, .hljs-symbol { color: ${theme === 'dark' ? '#f0b27a' : '#a64b00'}; }
    .hljs-comment, .hljs-quote { color: var(--text-secondary); font-style: italic; }
    .hljs-built_in, .hljs-type { color: ${theme === 'dark' ? '#82c7df' : '#146f8a'}; }
    table { width: 100%; margin: 4mm 0 5mm; border-collapse: collapse; table-layout: fixed; font-size: 7.45pt; line-height: 1.34; }
    thead { display: table-header-group; }
    tr { break-inside: avoid; page-break-inside: avoid; }
    th, td { border: .55pt solid var(--border); padding: 1.7mm 1.8mm; vertical-align: top; overflow-wrap: anywhere; word-break: normal; hyphens: auto; }
    th { background: var(--surface-raised); color: var(--heading); text-align: left; font-weight: 700; }
    tbody tr:nth-child(even) td { background: var(--surface-bg); }
    figure, img, svg { break-inside: avoid; page-break-inside: avoid; }
    img, svg { display: block; max-width: 100%; max-height: 190mm; height: auto; margin: 4mm auto; object-fit: contain; }
    .missing-image { width: 100%; height: 18mm; border: 1pt dashed var(--danger); background: var(--surface-bg); }
    hr { border: 0; border-top: .7pt solid var(--border); margin: 7mm 0; }
    .task-list-item { list-style: none; }
    .task-list-item-checkbox { margin: 0 1.5mm 0 -5mm; accent-color: var(--accent); }
    dl { margin: 0 0 4mm; }
    dt { color: var(--heading); font-weight: 700; margin-top: 2.5mm; }
    dd { margin: .8mm 0 2mm 5mm; }
    .footnotes { margin-top: 9mm; border-top: .7pt solid var(--border); font-size: 8.5pt; color: var(--text-secondary); }
    .linked-files-section, .unavailable-section { break-before: page; }
    .linked-files-section table { font-size: 7.2pt; }
    .unavailable-section { color: var(--danger); }
    math { font-size: 1.02em; }
  `;
}

function createHtml(task, renderedMarkdown, context, theme) {
  return `<!doctype html>
<html lang="af">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>${escapeHtml(task.title)}</title>
  <style>${stylesheet(theme)}</style>
</head>
<body>
  <main class="document">
    <div class="task-kicker">${escapeHtml(task.id)} · SmartEats PAT 2026</div>
    ${renderedMarkdown}
    ${linkedFilesSection(context)}
    ${missingItemsSection(context)}
  </main>
</body>
</html>`;
}

function browserExecutable() {
  const candidates = [
    process.env.CHROME_PATH,
    'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe',
    'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe',
    'C:\\Program Files\\Microsoft\\Edge\\Application\\msedge.exe',
  ].filter(Boolean);
  const found = candidates.find((candidate) => fs.existsSync(candidate));
  if (!found) {
    throw new Error('Chrome or Edge was not found. Set CHROME_PATH to a Chromium-based browser executable.');
  }
  return found;
}

function headerTemplate(task, theme) {
  const p = themePalette(theme);
  return `<div style="width:100%;padding:0 14mm;font-family:Segoe UI,Arial,sans-serif;font-size:7px;color:${p.secondary};display:flex;justify-content:space-between;align-items:center;">
    <span>${escapeHtml(task.title)}</span><span style="font-weight:600;letter-spacing:.08em;">${task.id}</span>
  </div>`;
}

function footerTemplate(task, theme) {
  const p = themePalette(theme);
  return `<div style="width:100%;padding:0 14mm;font-family:Segoe UI,Arial,sans-serif;font-size:7px;color:${p.secondary};display:flex;justify-content:space-between;align-items:center;">
    <span>${escapeHtml(path.basename(task.sourcePath))}</span><span>Bladsy <span class="pageNumber"></span> van <span class="totalPages"></span></span>
  </div>`;
}

function unique(values) {
  return [...new Set(values)];
}

async function buildTaskHtml(task, md) {
  const taskFiles = await listFilesRecursive(task.folder);
  const bundleDirectory = path.join(outputRoot, 'gekoppelde_leers', task.id);
  await resetDirectory(bundleDirectory);
  const context = {
    task,
    taskFiles,
    bundleDirectory,
    externalLinks: [],
    internalLinks: [],
    localLinks: [],
    unresolvedLinks: [],
    images: [],
    missingImages: [],
    copiedBySource: new Map(),
    usedBundleNames: new Set(),
  };
  const environment = {};
  const tokens = md.parse(task.sourceText, environment);
  await processTokenList(tokens, context);
  const renderedMarkdown = md.renderer.render(tokens, md.options, environment);
  context.externalLinks = unique(context.externalLinks);
  context.internalLinks = unique(context.internalLinks);
  return { context, renderedMarkdown };
}

async function renderPdf(page, task, html, theme) {
  const htmlPath = path.join(htmlRoot, `${task.id}-${theme}.html`);
  const pdfDirectory = path.join(outputRoot, theme === 'light' ? 'lig' : 'donker');
  await fsp.mkdir(pdfDirectory, { recursive: true });
  const pdfPath = path.join(pdfDirectory, `${task.id}.pdf`);
  await fsp.writeFile(htmlPath, html, 'utf8');
  await page.goto(pathToFileURL(htmlPath).href, { waitUntil: 'load' });
  await page.emulateMedia({ media: 'print', colorScheme: theme });
  await page.pdf({
    path: pdfPath,
    format: 'A4',
    printBackground: true,
    displayHeaderFooter: true,
    headerTemplate: headerTemplate(task, theme),
    footerTemplate: footerTemplate(task, theme),
    margin: { top: '18mm', right: '14mm', bottom: '16mm', left: '14mm' },
    preferCSSPageSize: true,
    tagged: true,
    outline: true,
  });
  return { theme, htmlPath, pdfPath, pdfRelative: path.relative(workspaceRoot, pdfPath) };
}

function markdownFeaturesText(features) {
  const labels = [];
  for (const [key, value] of Object.entries(features)) {
    if (value === true || (typeof value === 'number' && value > 0)) labels.push(key);
  }
  return labels.join(', ') || 'plain paragraphs only';
}

async function writeBuildReport(tasks, validation, versions) {
  const lines = [];
  lines.push('# PDF build report', '');
  lines.push(`Overall status: **${validation.overallPass ? 'PASS' : 'FAIL'}**.`, '');
  lines.push('## Build environment', '');
  lines.push(`- Build date: ${new Date().toISOString()}`);
  const visualReviewArgument = validation.manualVisualReview === 'PASS' ? ' -VisualReviewPass' : '';
  lines.push(`- Build command: \`pwsh -NoProfile -File .\\tools\\build-task-pdfs.ps1${visualReviewArgument}\``);
  lines.push(`- Node.js: ${process.version}`);
  lines.push(`- Chromium: ${versions.browser}`);
  lines.push(`- Python: ${validation.versions.python}`);
  lines.push(`- PyMuPDF: ${validation.versions.pymupdf}`);
  lines.push(`- pypdf: ${validation.versions.pypdf}`);
  lines.push('- Markdown renderer: markdown-it 14.1.0 with pinned feature plugins.');
  lines.push('');
  lines.push('## Source selection and outputs', '');
  lines.push('| Task | Selected source | Selection decision | Light PDF | Dark PDF | Pages (light/dark) |');
  lines.push('|---|---|---|---|---|---:|');
  for (const task of tasks) {
    const light = validation.pdfs.find((item) => item.taskId === task.id && item.theme === 'light');
    const dark = validation.pdfs.find((item) => item.taskId === task.id && item.theme === 'dark');
    lines.push(`| ${task.id} | \`${task.sourceRelative.replaceAll('\\', '/')}\` | ${task.selectionDecision} | \`${light.pdfRelative.replaceAll('\\', '/')}\` | \`${dark.pdfRelative.replaceAll('\\', '/')}\` | ${light.pageCount}/${dark.pageCount} |`);
  }
  lines.push('');
  lines.push('## Markdown and link audit', '');
  for (const task of tasks) {
    lines.push(`### ${task.id}`, '');
    lines.push(`Detected constructs: ${markdownFeaturesText(task.features)}.`);
    lines.push(`External links detected: ${task.externalLinks.length}.`);
    lines.push(`Internal heading links detected: ${task.internalLinks.length}.`);
    lines.push(`Local-file links detected and bundled: ${task.localLinks.length}.`);
    lines.push(`Embedded local images: ${task.images.length}.`);
    if (task.localLinks.length > 0) {
      lines.push('', '| Label | Bundled path | Source path | Resolution | PDF annotation |');
      lines.push('|---|---|---|---|---|');
      for (const link of task.localLinks) {
        const annotationFound = validation.pdfs
          .filter((item) => item.taskId === task.id)
          .every((item) => item.localAnnotationUris.some((uri) => decodeURI(uri).toLowerCase().includes(link.filename.toLowerCase())));
        lines.push(`| ${link.label.replaceAll('|', '\\|')} | \`${link.bundleRelative}\` | \`${link.sourceRelative.replaceAll('\\', '/')}\` | ${link.corrected ? `Corrected in generated HTML: ${link.correctionReason}` : 'Exact source-relative path'} | ${annotationFound ? 'Present in both PDFs' : 'Not verified; visible path is the fallback'} |`);
      }
    }
    if (task.unresolvedLinks.length > 0) {
      lines.push('', 'Unresolved links:');
      for (const item of task.unresolvedLinks) lines.push(`- \`${item.href}\`: ${item.reason}`);
    } else {
      lines.push('Unresolved links: none.');
    }
    if (task.missingImages.length > 0) {
      lines.push('', 'Missing images:');
      for (const item of task.missingImages) lines.push(`- \`${item.href}\`: ${item.reason}`);
    } else {
      lines.push('Missing images: none.');
    }
    lines.push('');
  }
  lines.push('## PDF validation', '');
  lines.push('| PDF | Pages | Extractable text | Title | Links | Background | Content coverage | Result |');
  lines.push('|---|---:|---|---|---|---|---:|---|');
  for (const pdf of validation.pdfs) {
    lines.push(`| \`${pdf.pdfRelative.replaceAll('\\', '/')}\` | ${pdf.pageCount} | ${pdf.hasExtractableText ? 'PASS' : 'FAIL'} | ${pdf.titlePresent ? 'PASS' : 'FAIL'} | ${pdf.linkValidationPass ? 'PASS' : 'FAIL'} | ${pdf.backgroundPass ? 'PASS' : 'FAIL'} | ${(pdf.contentCoverage * 100).toFixed(1)}% | ${pdf.pass ? 'PASS' : 'FAIL'} |`);
    for (const warning of pdf.warnings) lines.push(`|  |  |  |  | Warning | ${warning.replaceAll('|', '\\|')} |  |  |`);
  }
  lines.push('');
  lines.push('## Warnings and limitations', '');
  const allWarnings = unique(tasks.flatMap((task) => task.warnings));
  if (allWarnings.length === 0) lines.push('- No material build warnings remain.');
  else for (const warning of allWarnings) lines.push(`- ${warning}`);
  lines.push('- Local-file hyperlinks are security-policy and viewer dependent.');
  lines.push('- Both PDF variants contain a visible bundled path for every local file as a portable fallback.');
  lines.push('- Unsafe inline HTML and active scripts are disabled by the Markdown renderer.');
  lines.push('- Remote active content is not loaded during rendering.');
  lines.push('');
  lines.push('## Visual inspection', '');
  lines.push(`Rendered inspection images: \`${path.relative(workspaceRoot, renderRoot).replaceAll('\\', '/')}\`.`);
  lines.push('Every page was rendered to PNG for inspection, including all pages containing tables, code blocks, and local-file links.');
  lines.push(`Manual visual review: **${validation.manualVisualReview ?? 'PENDING'}**.`);
  lines.push('');
  lines.push('## Source integrity', '');
  const unchanged = tasks.every((task) => task.sourceHashBefore === task.sourceHashAfter);
  lines.push(`Original Markdown files modified: **${unchanged ? 'No' : 'Yes'}**.`);
  if (!unchanged) lines.push('At least one source hash changed during the build, so the overall status must remain FAIL.');
  lines.push('All link recovery was applied only to generated HTML intermediates.');
  lines.push('');
  lines.push(`Final result: **${validation.overallPass && unchanged ? 'PASS' : 'FAIL'}**.`);
  await fsp.writeFile(path.join(outputRoot, 'PDF_BUILD_REPORT.md'), `${lines.join('\n')}\n`, 'utf8');
}

async function main() {
  await fsp.mkdir(outputRoot, { recursive: true });
  await resetDirectory(tempRoot);
  await fsp.mkdir(htmlRoot, { recursive: true });
  await fsp.mkdir(renderRoot, { recursive: true });
  await fsp.mkdir(path.join(outputRoot, 'lig'), { recursive: true });
  await fsp.mkdir(path.join(outputRoot, 'donker'), { recursive: true });
  await fsp.mkdir(path.join(outputRoot, 'gekoppelde_leers'), { recursive: true });

  const tasks = await locateTasks();
  const md = createMarkdownRenderer();
  const executablePath = browserExecutable();
  const browser = await chromium.launch({ executablePath, headless: true, args: ['--allow-file-access-from-files'] });
  const browserVersion = await browser.version();
  const context = await browser.newContext({ javaScriptEnabled: false, locale: 'af-ZA' });
  await context.route(/https?:\/\//, (route) => route.abort());
  const page = await context.newPage();

  const manifestTasks = [];
  try {
    for (const task of tasks) {
      const { context: linkContext, renderedMarkdown } = await buildTaskHtml(task, md);
      const outputs = [];
      for (const theme of ['light', 'dark']) {
        outputs.push(await renderPdf(page, task, createHtml(task, renderedMarkdown, linkContext, theme), theme));
      }
      const sourceAfter = await fsp.readFile(task.sourcePath, 'utf8');
      manifestTasks.push({
        id: task.id,
        number: task.number,
        folderName: task.folderName,
        sourcePath: task.sourcePath,
        sourceRelative: task.sourceRelative,
        sourceHashBefore: task.sourceHashBefore,
        sourceHashAfter: sha256(sourceAfter),
        title: task.title,
        selectionDecision: task.selectionDecision,
        features: inspectMarkdown(task.sourceText),
        externalLinks: linkContext.externalLinks,
        internalLinks: linkContext.internalLinks,
        localLinks: linkContext.localLinks.map((link) => ({ ...link, filename: path.basename(link.destination) })),
        unresolvedLinks: linkContext.unresolvedLinks,
        images: linkContext.images,
        missingImages: linkContext.missingImages,
        warnings: [
          ...linkContext.localLinks.filter((link) => link.corrected).map((link) => `${task.id}: corrected \`${link.originalHref}\` only in generated output (${link.correctionReason})`),
          ...linkContext.unresolvedLinks.map((link) => `${task.id}: unresolved local link \`${link.href}\`.`),
          ...linkContext.missingImages.map((image) => `${task.id}: missing image \`${image.href}\`.`),
        ],
        outputs,
      });
      process.stdout.write(`Built ${task.id} light and dark PDFs.\n`);
    }
  } finally {
    await context.close();
    await browser.close();
  }

  const manifest = {
    workspaceRoot,
    outputRoot,
    renderRoot,
    tasks: manifestTasks,
  };
  await fsp.writeFile(manifestPath, JSON.stringify(manifest, null, 2), 'utf8');

  const validatorPython = process.env.SMART_EATS_PDF_PYTHON || 'python';
  const validationRun = spawnSync(validatorPython, [
    path.join(scriptDirectory, 'validate_task_pdfs.py'),
    '--manifest', manifestPath,
    '--output', validationPath,
    '--render-dir', renderRoot,
  ], { cwd: workspaceRoot, encoding: 'utf8' });
  if (validationRun.stdout) process.stdout.write(validationRun.stdout);
  if (validationRun.stderr) process.stderr.write(validationRun.stderr);
  if (validationRun.status !== 0 && !fs.existsSync(validationPath)) {
    throw new Error(`PDF validation could not run (exit ${validationRun.status}).`);
  }

  const validation = JSON.parse(await fsp.readFile(validationPath, 'utf8'));
  validation.manualVisualReview = process.argv.includes('--visual-review-pass') ? 'PASS' : 'PENDING';
  validation.overallPass = validation.automatedPass
    && manifestTasks.every((task) => task.sourceHashBefore === task.sourceHashAfter)
    && manifestTasks.every((task) => task.unresolvedLinks.length === 0 && task.missingImages.length === 0)
    && validation.manualVisualReview === 'PASS';
  await writeBuildReport(manifestTasks, validation, { browser: browserVersion });

  if (!validation.overallPass) {
    process.stderr.write('Build completed, but final PASS requires successful automated validation and an explicit visual review. See PDF_UITVOER/PDF_BUILD_REPORT.md.\n');
    process.exitCode = 1;
  } else {
    process.stdout.write('All ten PDFs passed automated validation.\n');
  }
}

main().catch((error) => {
  process.stderr.write(`${error.stack || error.message}\n`);
  process.exitCode = 1;
});
