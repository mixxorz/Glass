# Contributing

## Versioning

Glass uses `MAJOR.MINOR.PATCH` product versioning, not strict Semantic Versioning.
Choose versions based on the impact on users:

- **Patch (`2.0.1`):** Bug fixes and small polish.
- **Minor (`2.1.0`):** New features and meaningful improvements. This is the
  normal release category.
- **Major (`3.0.0`):** A substantial redesign or changes that significantly
  disrupt existing setups or workflows.

Internal refactors, WoW interface-number updates, and individual setting or
integration changes do not automatically require a major version. Preserve
existing settings and workflows where practical, provide automatic migrations
where possible, and explain changed or removed behavior in the changelog.
