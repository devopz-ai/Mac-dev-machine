# Changelog

All notable changes to Mac Dev Machine will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-03-16

### Added
- Initial release of Mac Dev Machine
- Three package tiers: light, standard, advanced
- Modular installation system with 11 modules
- Category-based exclusion (`--exclude`) during installation
- Add excluded categories later (`--only` mode)
- Add specific tools by name (`--add` mode)
- Smart tool installation (auto-detect brew formula/cask, or prompt for tap/url/pip/npm/custom)
- Update script with specific tool/category updates
- Auto-update feature with cron scheduling
- Auto-add/remove by category for auto-updates
- Uninstall script with tool/category support
- Package scanning and state tracking
- Validation script with actionable install commands
- Comprehensive documentation for AI agents
- Use-case guides for various development workflows
- Dotfiles configuration with backup

### Features
- **install.sh** - Main installer with package tiers and exclusions
- **update.sh** - Update tools manually or via scheduled cron
- **uninstall.sh** - Smart uninstall based on install method
- **scan-installed.sh** - Scan and record installed packages
- **tests/validate.sh** - Post-install validation

### Documentation
- README.md with comprehensive setup guide
- CLAUDE.md for AI agent instructions
- AGENT_INDEX.md for quick AI reference
- Use-case guides for web, API, DevOps, AI/ML, data, mobile, security, virtualization
- CONTRIBUTING.md for contributors
- CODE_OF_CONDUCT.md for community standards

---

## Version History

| Version | Date | Description |
|---------|------|-------------|
| 1.0.0 | 2026-03-16 | Initial release |

---

## Versioning

We use [Semantic Versioning](https://semver.org/):

- **MAJOR** version for incompatible changes
- **MINOR** version for new features (backwards compatible)
- **PATCH** version for bug fixes (backwards compatible)

## Links

- [GitHub Releases](https://github.com/devopz-ai/Mac-dev-machine/releases)
- [Compare Changes](https://github.com/devopz-ai/Mac-dev-machine/compare)
