#!/usr/bin/env python3
"""Validate that article code blocks match the canonical examples directory."""

import argparse
import re
import sys
from pathlib import Path


EXTENSIONS = {
    "cangjie": ".cj",
    "java": ".java",
    "go": ".go",
    "kotlin": ".kt",
    "swift": ".swift",
    "rust": ".rs",
    "cpp": ".cpp",
    "zig": ".zig",
    "python": ".py",
}
FENCE_RE = re.compile(r"```([A-Za-z0-9_+-]+)\n(.*?)```", re.DOTALL)
MARKER_RE = re.compile(r"<!--\s*example:\s*([^\s]+)\s*-->\s*$")


def normalized(text):
    """Ignore only line-ending and trailing-whitespace differences."""
    return "\n".join(line.rstrip() for line in text.strip().splitlines())


def article_files(articles_dir):
    for path in sorted(articles_dir.glob("**/*.md")):
        if "templates" not in path.relative_to(articles_dir).parts:
            yield path


def main():
    parser = argparse.ArgumentParser(
        description="Check article code blocks against examples/"
    )
    parser.add_argument("--articles-dir", default="articles", type=Path)
    parser.add_argument("--examples-dir", default="examples", type=Path)
    args = parser.parse_args()

    errors = []
    references = {}
    source_files = {
        path.relative_to(args.examples_dir).as_posix(): path
        for path in args.examples_dir.glob("**/*")
        if path.is_file() and path.suffix in EXTENSIONS.values()
    }

    for article in article_files(args.articles_dir):
        content = article.read_text(encoding="utf-8")
        for match in FENCE_RE.finditer(content):
            language, code = match.groups()
            previous_lines = content[: match.start()].splitlines()
            marker_match = MARKER_RE.search(previous_lines[-1]) if previous_lines else None
            if language not in EXTENSIONS:
                continue
            if not marker_match:
                errors.append(
                    f"{article}: unmarked {language} code block at line "
                    f"{content.count(chr(10), 0, match.start()) + 1}"
                )
                continue

            relative = marker_match.group(1)
            source = source_files.get(relative)
            if source is None:
                errors.append(f"{article}: marker references missing {relative}")
                continue
            if source.suffix != EXTENSIONS[language]:
                errors.append(f"{article}: {relative} is not a {language} example")
            if normalized(code) != normalized(source.read_text(encoding="utf-8")):
                errors.append(f"{article}: code differs from {relative}")
            references.setdefault(relative, []).append(str(article))

    for relative in sorted(source_files):
        if relative not in references:
            errors.append(f"{relative}: not referenced by an article")

    if errors:
        print("Example synchronization failed:")
        for error in errors:
            print(f"- {error}")
        return 1

    print(f"Example synchronization passed: {len(references)} canonical examples")
    return 0


if __name__ == "__main__":
    sys.exit(main())
