# Third-party source and provenance

This file defines the information that must accompany a 1.0 package. It is not
a substitute for the license texts shipped by the upstream projects.

## FS-UAE

- Release baseline: FS-UAE 3.2.35.
- License baseline: GPL-2.0-only, as recorded by the tested distro package.
- Each package writes the executable SHA-256 and reported version to
  `bin/fs-uae/BUNDLE_INFO.txt`.
- The exact corresponding source archive, its SHA-256, build recipe, compiler
  and any patch series must be recorded before 1.0 RC.
- A copied distro executable is acceptable for development artifacts only. A
  final package must satisfy the corresponding-source and bundled-library
  obligations for the exact binary it ships.

## AROS

- Runtime identity shown by the current ROM: Git revision `f8e1bic2e`, built
  2026-06-21.
- Included ROM SHA-256 values and the source/rebuild reference must be frozen in
  the 1.0 package manifest.

## Enemy media and artwork

- The repository currently relies on the project owner's statement that Enemy
  is freeware and redistribution permission exists.
- The written permission and its covered files must be archived before 1.0 RC.
  Public packages should describe the permission without exposing private
  correspondence unnecessarily.

## Shaders and assets

- Preserve notices embedded in `super-xbr-3p.shader`.
- Confirm and document the origin and redistribution terms of every additional
  shader and launcher artwork file before 1.0 RC.

Any missing source, license or distribution evidence remains a release blocker;
it must not be converted into a pass by changing this document.
