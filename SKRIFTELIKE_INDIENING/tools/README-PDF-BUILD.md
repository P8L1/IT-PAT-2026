# SmartEats task PDF build

## Prerequisites

Install Node.js 20 or newer, Python 3.11 or newer, and Google Chrome or Microsoft Edge.
The build wrapper installs pinned Node and Python packages into this workspace only.
It does not change global packages or download fonts.

## Build command

Run this command from the workspace root:

```powershell
pwsh -NoProfile -File .\tools\build-task-pdfs.ps1
```

After inspecting the newly rendered PNG pages, an operator can record that review in the final report with:

```powershell
pwsh -NoProfile -File .\tools\build-task-pdfs.ps1 -VisualReviewPass
```

Use `-VisualReviewPass` only when the pages produced by the same pipeline and styles have actually been reviewed.

The first run creates `node_modules`, `package-lock.json`, and `tools/.venv`.
Later runs reuse those pinned project-local dependencies.

## Output

Light PDFs are written to `PDF_UITVOER/lig` and dark PDFs to `PDF_UITVOER/donker`.
Local files linked by the source documents are copied to `PDF_UITVOER/gekoppelde_leers/<TAAK>`.
The audit and validation summary is written to `PDF_UITVOER/PDF_BUILD_REPORT.md`.
Rendered inspection images and other disposable intermediates stay under `tmp/pdfs`.

## Local-link limitation

Web links and same-document anchors are retained as PDF annotations when Chromium supports them.
Links to bundled local files are also attempted, but PDF viewers apply different security policies to local-file links.
Every bundled path is therefore printed visibly in the generated document and recorded in the build report.

## Troubleshooting

If Chrome is installed in a nonstandard location, set `CHROME_PATH` to the browser executable before running the build.
If dependencies appear inconsistent, remove only `node_modules` and `tools/.venv`, then rerun the build wrapper.
Do not remove the source task folders or edit their Markdown to work around a conversion warning; fix path handling in the build script instead.
