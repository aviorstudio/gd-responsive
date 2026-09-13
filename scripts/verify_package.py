#!/usr/bin/env python3
from __future__ import annotations

import hashlib
import pathlib
import stat
import sys
import zipfile


def fail(message: str) -> None:
    raise SystemExit(f"package verification failed: {message}")


if len(sys.argv) != 3:
    fail("usage: verify_package.py MANIFEST ZIP")

manifest_path = pathlib.Path(sys.argv[1])
zip_path = pathlib.Path(sys.argv[2])
expected = manifest_path.read_text(encoding="utf-8").splitlines()
if not expected or any(not item for item in expected):
    fail("manifest is empty or contains blank entries")
if expected != sorted(expected) or len(expected) != len(set(expected)):
    fail("manifest must be sorted and unique")

with zipfile.ZipFile(zip_path) as archive:
    files: list[str] = []
    for info in archive.infolist():
        name = info.filename
        path = pathlib.PurePosixPath(name)
        if path.is_absolute() or ".." in path.parts:
            fail(f"unsafe archive path: {name}")
        mode = info.external_attr >> 16
        if stat.S_ISLNK(mode):
            fail(f"archive symlink: {name}")
        if not info.is_dir():
            files.append(name)
    files.sort()
    if files != expected:
        fail(f"closed manifest mismatch\nexpected={expected!r}\nactual={files!r}")

digest = hashlib.sha256(zip_path.read_bytes()).hexdigest()
print(f"PACKAGE_VERIFIED files={len(expected)} sha256={digest}")
