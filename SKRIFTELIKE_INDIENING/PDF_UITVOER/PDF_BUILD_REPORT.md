# PDF build report

Overall status: **PASS**.

## Build environment

- Build date: 2026-08-06T12:15:21.915Z
- Build command: `pwsh -NoProfile -File .\tools\build-task-pdfs.ps1 -VisualReviewPass`
- Node.js: v24.11.1
- Chromium: 150.0.7871.189
- Python: 3.13.5
- PyMuPDF: 1.26.3
- pypdf: 6.0.0
- Markdown renderer: markdown-it 14.1.0 with pinned feature plugins.

## Source selection and outputs

| Task | Selected source | Selection decision | Light PDF | Dark PDF | Pages (light/dark) |
|---|---|---|---|---|---:|
| TAAK1 | `Taak_1/TAAK_1.md` | The folder contains exactly one Markdown file. | `PDF_UITVOER/lig/TAAK1.pdf` | `PDF_UITVOER/donker/TAAK1.pdf` | 2/2 |
| TAAK2 | `Taak_2/TAAK_2_DATAWOORDEBOEK.md` | The folder contains exactly one Markdown file. | `PDF_UITVOER/lig/TAAK2.pdf` | `PDF_UITVOER/donker/TAAK2.pdf` | 4/4 |
| TAAK3 | `Taak_3/TAAK_3_DATABASISONTWERP.md` | The folder contains exactly one Markdown file. | `PDF_UITVOER/lig/TAAK3.pdf` | `PDF_UITVOER/donker/TAAK3.pdf` | 4/4 |
| TAAK4 | `Taak_4/TAAK_4_NAVIGASIE_EN_GGK.md` | The folder contains exactly one Markdown file. | `PDF_UITVOER/lig/TAAK4.pdf` | `PDF_UITVOER/donker/TAAK4.pdf` | 4/4 |
| TAAK5 | `Taak_5/TAAK_5_TVA_EN_VALIDERING.md` | The folder contains exactly one Markdown file. | `PDF_UITVOER/lig/TAAK5.pdf` | `PDF_UITVOER/donker/TAAK5.pdf` | 6/6 |

## Markdown and link audit

### TAAK1

Detected constructs: headings, tables.
External links detected: 0.
Internal heading links detected: 0.
Local-file links detected and bundled: 0.
Embedded local images: 0.
Unresolved links: none.
Missing images: none.

### TAAK2

Detected constructs: headings, tables, inlineCode.
External links detected: 0.
Internal heading links detected: 0.
Local-file links detected and bundled: 0.
Embedded local images: 0.
Unresolved links: none.
Missing images: none.

### TAAK3

Detected constructs: headings, tables, blockquotes, inlineCode.
External links detected: 0.
Internal heading links detected: 0.
Local-file links detected and bundled: 0.
Embedded local images: 0.
Unresolved links: none.
Missing images: none.

### TAAK4

Detected constructs: headings, tables, unorderedLists, blockquotes, inlineCode, localLinks.
External links detected: 0.
Internal heading links detected: 0.
Local-file links detected and bundled: 6.
Embedded local images: 0.

| Label | Bundled path | Source path | Resolution | PDF annotation |
|---|---|---|---|---|
| SmartEats-programvloei | `gekoppelde_leers/TAAK4/Programvloei.pdf` | `Taak_4/Lucidchart/Programvloei.pdf` | Corrected in generated HTML: The source filename was missing; recovered the only file of the requested type in the named task subfolder. | Present in both PDFs |
| Dashboard en gekoppelde Release-UI | `gekoppelde_leers/TAAK4/release-loop.png` | `Taak_4/Skermkopiee/release-loop.png` | Corrected in generated HTML: The source-relative path was missing; recovered the only same-named file inside the task folder. | Present in both PDFs |
| Spyskaartitemwysiging | `gekoppelde_leers/TAAK4/grensitem-wysig.png` | `Taak_4/Skermkopiee/grensitem-wysig.png` | Corrected in generated HTML: The source-relative path was missing; recovered the only same-named file inside the task folder. | Present in both PDFs |
| Geldige bestelling | `gekoppelde_leers/TAAK4/bestelling-skep.png` | `Taak_4/Skermkopiee/bestelling-skep.png` | Corrected in generated HTML: The source-relative path was missing; recovered the only same-named file inside the task folder. | Present in both PDFs |
| Dagverslag | `gekoppelde_leers/TAAK4/dagverslag.png` | `Taak_4/Skermkopiee/dagverslag.png` | Corrected in generated HTML: The source-relative path was missing; recovered the only same-named file inside the task folder. | Present in both PDFs |
| Veilige sluitbevestiging | `gekoppelde_leers/TAAK4/sluitbevestiging.png` | `Taak_4/Skermkopiee/sluitbevestiging.png` | Corrected in generated HTML: The source-relative path was missing; recovered the only same-named file inside the task folder. | Present in both PDFs |
Unresolved links: none.
Missing images: none.

### TAAK5

Detected constructs: headings, tables, orderedLists, fencedCode, inlineCode.
External links detected: 0.
Internal heading links detected: 0.
Local-file links detected and bundled: 0.
Embedded local images: 0.
Unresolved links: none.
Missing images: none.

## PDF validation

| PDF | Pages | Extractable text | Title | Links | Background | Content coverage | Result |
|---|---:|---|---|---|---|---:|---|
| `PDF_UITVOER/lig/TAAK1.pdf` | 2 | PASS | PASS | PASS | PASS | 100.0% | PASS |
| `PDF_UITVOER/donker/TAAK1.pdf` | 2 | PASS | PASS | PASS | PASS | 100.0% | PASS |
| `PDF_UITVOER/lig/TAAK2.pdf` | 4 | PASS | PASS | PASS | PASS | 100.0% | PASS |
| `PDF_UITVOER/donker/TAAK2.pdf` | 4 | PASS | PASS | PASS | PASS | 100.0% | PASS |
| `PDF_UITVOER/lig/TAAK3.pdf` | 4 | PASS | PASS | PASS | PASS | 99.1% | PASS |
| `PDF_UITVOER/donker/TAAK3.pdf` | 4 | PASS | PASS | PASS | PASS | 99.1% | PASS |
| `PDF_UITVOER/lig/TAAK4.pdf` | 4 | PASS | PASS | PASS | PASS | 100.0% | PASS |
| `PDF_UITVOER/donker/TAAK4.pdf` | 4 | PASS | PASS | PASS | PASS | 100.0% | PASS |
| `PDF_UITVOER/lig/TAAK5.pdf` | 6 | PASS | PASS | PASS | PASS | 98.5% | PASS |
| `PDF_UITVOER/donker/TAAK5.pdf` | 6 | PASS | PASS | PASS | PASS | 98.5% | PASS |

## Warnings and limitations

- TAAK4: corrected `../Lucidchart/SmartEats-Programvloei-PAT-2026.pdf` only in generated output (The source filename was missing; recovered the only file of the requested type in the named task subfolder.)
- TAAK4: corrected `..\Skermkopiee\release-loop.png` only in generated output (The source-relative path was missing; recovered the only same-named file inside the task folder.)
- TAAK4: corrected `..\Skermkopiee\grensitem-wysig.png` only in generated output (The source-relative path was missing; recovered the only same-named file inside the task folder.)
- TAAK4: corrected `..\Skermkopiee\bestelling-skep.png` only in generated output (The source-relative path was missing; recovered the only same-named file inside the task folder.)
- TAAK4: corrected `..\Skermkopiee\dagverslag.png` only in generated output (The source-relative path was missing; recovered the only same-named file inside the task folder.)
- TAAK4: corrected `..\Skermkopiee\sluitbevestiging.png` only in generated output (The source-relative path was missing; recovered the only same-named file inside the task folder.)
- Local-file hyperlinks are security-policy and viewer dependent.
- Both PDF variants contain a visible bundled path for every local file as a portable fallback.
- Unsafe inline HTML and active scripts are disabled by the Markdown renderer.
- Remote active content is not loaded during rendering.

## Visual inspection

Rendered inspection images: `tmp/pdfs/rendered`.
Every page was rendered to PNG for inspection, including all pages containing tables, code blocks, and local-file links.
Manual visual review: **PASS**.

## Source integrity

Original Markdown files modified: **No**.
All link recovery was applied only to generated HTML intermediates.

Final result: **PASS**.
