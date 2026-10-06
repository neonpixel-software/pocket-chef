#!/usr/bin/env python3
"""Fails when line coverage of a source folder is below a minimum (issue #135).

Usage: check-coverage.py --source <repo-relative dir> --min <percent> <report>...

Reads SonarQube generic coverage XML (the Swift reports from app/Scripts/xccov-to-sonarqube-generic.sh)
and Cobertura XML (coverlet's default for the .NET tests). A line counts as covered when any
report covers it, so several test projects' reports add up. Only files under --source count,
minus the globs in .github/coverage-exclusions.txt. Paths in the reports may be absolute; they
are made relative to the repository root, which is the current directory.
"""

import argparse
import fnmatch
import os
import sys
import xml.etree.ElementTree as ElementTree

EXCLUSIONS_FILE = os.path.join(os.path.dirname(__file__), "..", "coverage-exclusions.txt")


def load_exclusions():
    """The globs, trimmed, without blank and # lines. ci.yml's SonarCloud step reads the same way."""
    with open(EXCLUSIONS_FILE, encoding="utf-8") as file:
        lines = [line.strip() for line in file]
    return [line for line in lines if line and not line.startswith("#")]


def repo_relative(path):
    return os.path.relpath(os.path.normpath(path), os.getcwd())


def generic_lines(root):
    for file in root.iter("file"):
        for line in file.iter("lineToCover"):
            yield file.get("path"), int(line.get("lineNumber")), line.get("covered") == "true"


def cobertura_lines(root):
    sources = [source.text for source in root.iter("source") if source.text] or [""]
    for cls in root.iter("class"):
        filename = cls.get("filename")
        path = next(
            (os.path.join(source, filename) for source in sources
             if os.path.exists(os.path.join(source, filename))),
            os.path.join(sources[0], filename),
        )
        for line in cls.iter("line"):
            yield path, int(line.get("number")), int(line.get("hits")) > 0


def read_report(report):
    root = ElementTree.parse(report).getroot()
    if root.tag == "coverage" and root.find("file") is not None:
        return generic_lines(root)
    if root.tag == "coverage":
        return cobertura_lines(root)
    sys.exit(f"{report}: not a generic or Cobertura coverage report")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--source", required=True, help="repo-relative folder that must be covered")
    parser.add_argument("--min", type=float, required=True, help="minimum line coverage in percent")
    parser.add_argument("reports", nargs="+")
    args = parser.parse_args()

    source = args.source.rstrip("/") + "/"
    exclusions = load_exclusions()
    covered_by_line = {}
    for report in args.reports:
        for path, number, covered in read_report(report):
            path = repo_relative(path)
            if not path.startswith(source) or any(fnmatch.fnmatch(path, glob) for glob in exclusions):
                continue
            key = (path, number)
            covered_by_line[key] = covered_by_line.get(key, False) or covered

    total = len(covered_by_line)
    if total == 0:
        sys.exit(f"No coverable lines under {source} in {', '.join(args.reports)}: check the report paths")
    covered = sum(covered_by_line.values())
    percent = 100 * covered / total

    uncovered_by_file = {}
    for (path, _), is_covered in covered_by_line.items():
        if not is_covered:
            uncovered_by_file[path] = uncovered_by_file.get(path, 0) + 1
    print("Most uncovered lines:")
    for path, count in sorted(uncovered_by_file.items(), key=lambda item: -item[1])[:10]:
        print(f"  {count:4}  {path}")
    print(f"Line coverage of {source}: {covered}/{total} = {percent:.1f}% (minimum {args.min:g}%)")
    if percent < args.min:
        print(f"::error::Line coverage of {source} is {percent:.1f}%, below the {args.min:g}% minimum")
        sys.exit(1)


if __name__ == "__main__":
    main()
