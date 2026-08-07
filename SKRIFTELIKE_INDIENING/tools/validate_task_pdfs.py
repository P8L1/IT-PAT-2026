from __future__ import annotations

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path
from urllib.parse import unquote

import fitz
from PIL import Image, ImageDraw
from pypdf import PdfReader, PdfWriter
from pypdf.generic import NameObject, TextStringObject


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate and render the SmartEats task PDFs.")
    parser.add_argument("--manifest", required=True, type=Path)
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--render-dir", required=True, type=Path)
    return parser.parse_args()


def normalize_text(value: str) -> str:
    normalized = unicodedata.normalize("NFKD", value).casefold()
    return " ".join(re.findall(r"[a-z0-9]+", normalized))


def meaningful_words(value: str) -> set[str]:
    normalized = unicodedata.normalize("NFKD", value).casefold()
    return {word for word in re.findall(r"[a-z0-9]+", normalized) if len(word) >= 4}


def source_content_coverage(source: str, extracted: str) -> float:
    source_words = meaningful_words(source)
    if not source_words:
        return 1.0
    extracted_words = meaningful_words(extracted)
    return len(source_words & extracted_words) / len(source_words)


def median_luminance(image: Image.Image) -> float:
    histogram = image.convert("L").histogram()
    midpoint = sum(histogram) / 2
    total = 0
    for value, count in enumerate(histogram):
        total += count
        if total >= midpoint:
            return float(value)
    return 255.0


def pdf_annotations(reader: PdfReader) -> tuple[list[str], int]:
    uris: list[str] = []
    internal_destinations = 0
    for page in reader.pages:
        annotations = page.get("/Annots") or []
        for annotation_reference in annotations:
            try:
                annotation = annotation_reference.get_object()
            except Exception:
                continue
            if str(annotation.get("/Subtype")) != "/Link":
                continue
            action = annotation.get("/A")
            if action:
                try:
                    action = action.get_object()
                except Exception:
                    pass
                uri = action.get("/URI") if hasattr(action, "get") else None
                file_target = action.get("/F") if hasattr(action, "get") else None
                if uri:
                    uris.append(str(uri))
                elif file_target:
                    uris.append(str(file_target))
                if hasattr(action, "get") and action.get("/S") in ("/GoTo", "/GoToR"):
                    internal_destinations += 1
            if annotation.get("/Dest") is not None:
                internal_destinations += 1
    return uris, internal_destinations


def make_local_links_portable(pdf_path: Path, task: dict) -> int:
    if not task["localLinks"]:
        return 0
    reader = PdfReader(str(pdf_path), strict=False)
    writer = PdfWriter()
    writer.clone_document_from_reader(reader)
    replacements = {
        Path(link["destination"]).name.casefold(): f"../{link['bundleRelative']}"
        for link in task["localLinks"]
    }
    changed = 0
    for page in writer.pages:
        for annotation_reference in page.get("/Annots") or []:
            try:
                annotation = annotation_reference.get_object()
                action = annotation.get("/A")
                if action:
                    action = action.get_object()
            except Exception:
                continue
            uri = str(action.get("/URI") or "") if action else ""
            if not uri.lower().startswith("file:///"):
                continue
            decoded_uri = unquote(uri).replace("\\", "/")
            filename = Path(decoded_uri).name.casefold()
            replacement = replacements.get(filename)
            if replacement:
                action[NameObject("/URI")] = TextStringObject(replacement)
                changed += 1
    if changed:
        temporary_path = pdf_path.with_suffix(".portable.tmp.pdf")
        with temporary_path.open("wb") as stream:
            writer.write(stream)
        temporary_path.replace(pdf_path)
    return changed


def render_pdf(pdf_path: Path, destination: Path, stem: str) -> tuple[list[Path], list[float]]:
    document = fitz.open(pdf_path)
    page_paths: list[Path] = []
    medians: list[float] = []
    for page_index, page in enumerate(document):
        inspection_pixmap = page.get_pixmap(matrix=fitz.Matrix(1.5, 1.5), alpha=False)
        page_path = destination / f"{stem}-page-{page_index + 1:02d}.png"
        inspection_pixmap.save(page_path)
        page_paths.append(page_path)

        background_pixmap = page.get_pixmap(matrix=fitz.Matrix(0.45, 0.45), alpha=False)
        background_image = Image.frombytes(
            "RGB",
            (background_pixmap.width, background_pixmap.height),
            background_pixmap.samples,
        )
        medians.append(median_luminance(background_image))
    document.close()
    return page_paths, medians


def create_contact_sheet(page_paths: list[Path], destination: Path, title: str) -> None:
    if not page_paths:
        return
    thumbnail_width = 620
    gap = 24
    title_height = 54
    thumbnails: list[Image.Image] = []
    for page_path in page_paths:
        with Image.open(page_path) as source:
            thumbnail = source.convert("RGB")
            height = round(thumbnail.height * thumbnail_width / thumbnail.width)
            thumbnail = thumbnail.resize((thumbnail_width, height), Image.Resampling.LANCZOS)
            thumbnails.append(thumbnail)
    columns = 2
    rows = (len(thumbnails) + columns - 1) // columns
    row_height = max(image.height for image in thumbnails)
    sheet = Image.new(
        "RGB",
        (columns * thumbnail_width + (columns + 1) * gap, title_height + rows * row_height + (rows + 1) * gap),
        "#d7dbe0",
    )
    draw = ImageDraw.Draw(sheet)
    draw.text((gap, 16), title, fill="#1f252b")
    for index, thumbnail in enumerate(thumbnails):
        column = index % columns
        row = index // columns
        x = gap + column * (thumbnail_width + gap)
        y = title_height + gap + row * (row_height + gap)
        sheet.paste(thumbnail, (x, y))
        draw.text((x + 8, y + 8), f"Page {index + 1}", fill="#b00020", stroke_fill="#ffffff", stroke_width=2)
    sheet.save(destination, optimize=True)


def validate_pdf(
    task: dict,
    output: dict,
    render_directory: Path,
    workspace_root: Path,
) -> dict:
    pdf_path = Path(output["pdfPath"])
    theme = output["theme"]
    result = {
        "taskId": task["id"],
        "theme": theme,
        "pdfPath": str(pdf_path),
        "pdfRelative": str(pdf_path.relative_to(workspace_root)),
        "exists": pdf_path.is_file(),
        "nonEmpty": pdf_path.is_file() and pdf_path.stat().st_size > 1000,
        "pageCount": 0,
        "hasExtractableText": False,
        "titlePresent": False,
        "externalAnnotationUris": [],
        "localAnnotationUris": [],
        "internalAnnotationCount": 0,
        "linkValidationPass": False,
        "backgroundMedians": [],
        "backgroundPass": False,
        "contentCoverage": 0.0,
        "afrikaansCharactersPass": False,
        "temporaryTextAbsent": False,
        "warnings": [],
        "errors": [],
        "pass": False,
    }
    if not result["exists"] or not result["nonEmpty"]:
        result["errors"].append("The PDF is missing or empty.")
        return result

    try:
        portable_link_count = make_local_links_portable(pdf_path, task)
        if task["localLinks"] and portable_link_count == 0:
            result["warnings"].append(
                "No machine-specific local-file annotations could be rewritten to portable bundle-relative targets."
            )
        reader = PdfReader(str(pdf_path), strict=False)
        result["pageCount"] = len(reader.pages)
        extracted_text = "\n".join(page.extract_text() or "" for page in reader.pages)
        result["hasExtractableText"] = bool(extracted_text.strip())
        result["titlePresent"] = normalize_text(task["title"]) in normalize_text(extracted_text)
        uris, internal_destinations = pdf_annotations(reader)
        result["internalAnnotationCount"] = internal_destinations
        result["externalAnnotationUris"] = [
            uri for uri in uris if uri.lower().startswith(("http://", "https://", "mailto:"))
        ]
        result["localAnnotationUris"] = [
            uri for uri in uris if not uri.lower().startswith(("http://", "https://", "mailto:"))
        ]

        expected_external = task["externalLinks"]
        external_links_pass = all(
            any(uri == expected or unquote(uri) == unquote(expected) for uri in result["externalAnnotationUris"])
            for expected in expected_external
        )
        internal_links_pass = not task["internalLinks"] or internal_destinations >= len(task["internalLinks"])
        result["linkValidationPass"] = external_links_pass and internal_links_pass
        if task["localLinks"] and not result["localAnnotationUris"]:
            result["warnings"].append(
                "The local files were bundled, but this Chromium build did not expose portable local-link annotations."
            )

        source_text = Path(task["sourcePath"]).read_text(encoding="utf-8")
        result["contentCoverage"] = source_content_coverage(source_text, extracted_text)
        special_characters = {
            char for char in source_text if ord(char) > 127 and not char.isspace()
        }
        if special_characters:
            present = sum(1 for char in special_characters if char in extracted_text)
            result["afrikaansCharactersPass"] = present / len(special_characters) >= 0.7
        else:
            result["afrikaansCharactersPass"] = True
        lowered_text = extracted_text.casefold()
        result["temporaryTextAbsent"] = all(
            marker not in lowered_text
            for marker in ("tmp/pdfs", "tmp\\pdfs", ".pdf-build", "file:///", "localhost:")
        )
    except Exception as error:
        result["errors"].append(f"PDF parsing failed: {error}")
        return result

    try:
        stem = f"{task['id']}-{theme}"
        page_paths, medians = render_pdf(pdf_path, render_directory, stem)
        result["backgroundMedians"] = medians
        if theme == "dark":
            result["backgroundPass"] = bool(medians) and all(value < 125 for value in medians)
        else:
            result["backgroundPass"] = bool(medians) and all(value > 205 for value in medians)
        create_contact_sheet(page_paths, render_directory / f"{stem}-contact.png", f"{task['id']} - {theme}")
    except Exception as error:
        result["errors"].append(f"Rendering failed: {error}")

    copied_files_pass = all(Path(link["destination"]).is_file() for link in task["localLinks"])
    missing_assets_pass = not task["missingImages"]
    result["pass"] = all(
        (
            result["exists"],
            result["nonEmpty"],
            result["pageCount"] >= 1,
            result["hasExtractableText"],
            result["titlePresent"],
            result["linkValidationPass"],
            result["backgroundPass"],
            result["contentCoverage"] >= 0.82,
            result["afrikaansCharactersPass"],
            result["temporaryTextAbsent"],
            copied_files_pass,
            missing_assets_pass,
            not result["errors"],
        )
    )
    if result["contentCoverage"] < 0.82:
        result["errors"].append(
            f"Extracted text covers only {result['contentCoverage']:.1%} of meaningful source words."
        )
    if not result["backgroundPass"]:
        result["errors"].append(
            f"The {theme} background threshold failed on at least one page: {result['backgroundMedians']}."
        )
    return result


def main() -> int:
    args = parse_args()
    manifest = json.loads(args.manifest.read_text(encoding="utf-8"))
    workspace_root = Path(manifest["workspaceRoot"])
    args.render_dir.mkdir(parents=True, exist_ok=True)

    results: list[dict] = []
    for task in manifest["tasks"]:
        for output in task["outputs"]:
            result = validate_pdf(task, output, args.render_dir, workspace_root)
            results.append(result)
            status = "PASS" if result["pass"] else "FAIL"
            print(f"Validated {task['id']} {output['theme']}: {status} ({result['pageCount']} pages)")

    validation = {
        "versions": {
            "python": sys.version.split()[0],
            "pymupdf": fitz.version[0],
            "pypdf": __import__("pypdf").__version__,
        },
        "pdfs": results,
        "automatedPass": len(results) == 10 and all(result["pass"] for result in results),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(validation, indent=2, ensure_ascii=False), encoding="utf-8")
    return 0 if validation["automatedPass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
