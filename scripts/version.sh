#!/bin/bash
#
# Mac Dev Machine - Version Management Script
# Handles version bumping, tagging, and release preparation
#
# Copyright (c) 2024-2026 Devopz.ai
# Author: Rashed Ahmed <rashed.ahmed@devopz.ai>
# License: MIT
#
# Usage:
#   ./scripts/version.sh                    # Show current version
#   ./scripts/version.sh --bump patch       # Bump patch version (1.0.0 -> 1.0.1)
#   ./scripts/version.sh --bump minor       # Bump minor version (1.0.0 -> 1.1.0)
#   ./scripts/version.sh --bump major       # Bump major version (1.0.0 -> 2.0.0)
#   ./scripts/version.sh --set 2.0.0        # Set specific version
#   ./scripts/version.sh --tag              # Create git tag for current version
#   ./scripts/version.sh --release patch    # Bump, commit, tag, and push
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION_FILE="$ROOT_DIR/VERSION"
CHANGELOG_FILE="$ROOT_DIR/CHANGELOG.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Get current version
get_version() {
    if [[ -f "$VERSION_FILE" ]]; then
        cat "$VERSION_FILE" | tr -d '\n'
    else
        echo "0.0.0"
    fi
}

# Set version
set_version() {
    local new_version="$1"
    echo "$new_version" > "$VERSION_FILE"
    echo -e "${GREEN}Version set to:${NC} $new_version"
}

# Bump version
bump_version() {
    local bump_type="$1"
    local current=$(get_version)

    # Parse current version
    local major=$(echo "$current" | cut -d. -f1)
    local minor=$(echo "$current" | cut -d. -f2)
    local patch=$(echo "$current" | cut -d. -f3)

    case "$bump_type" in
        major)
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        minor)
            minor=$((minor + 1))
            patch=0
            ;;
        patch)
            patch=$((patch + 1))
            ;;
        *)
            echo -e "${RED}Error:${NC} Invalid bump type: $bump_type"
            echo "Use: major, minor, or patch"
            exit 1
            ;;
    esac

    local new_version="${major}.${minor}.${patch}"
    set_version "$new_version"
    echo "$new_version"
}

# Create git tag and push to GitHub
create_tag() {
    local version=$(get_version)
    local tag_name="v${version}"
    local auto_push="${1:-false}"

    # Check if tag already exists locally
    if git rev-parse "$tag_name" >/dev/null 2>&1; then
        echo -e "${YELLOW}Warning:${NC} Tag $tag_name already exists locally"
        read -p "Delete and recreate? [y/N]: " confirm
        if [[ "$confirm" =~ ^[Yy]$ ]]; then
            git tag -d "$tag_name"
            git push origin --delete "$tag_name" 2>/dev/null || true
        else
            echo "Aborted"
            exit 1
        fi
    fi

    # Create annotated tag
    echo -e "${CYAN}Creating tag:${NC} $tag_name"
    git tag -a "$tag_name" -m "Release $version

Mac Dev Machine v${version}
https://github.com/devopz-ai/Mac-dev-machine

Changes in this release - see CHANGELOG.md"

    echo -e "${GREEN}Tag created:${NC} $tag_name"

    # Auto-push if requested
    if [[ "$auto_push" == "true" ]]; then
        echo ""
        echo -e "${CYAN}Pushing tag to GitHub...${NC}"
        if git push origin "$tag_name"; then
            echo -e "${GREEN}Tag pushed successfully!${NC}"
            echo ""
            echo -e "View release: ${BLUE}https://github.com/devopz-ai/Mac-dev-machine/releases/tag/$tag_name${NC}"
        else
            echo -e "${RED}Failed to push tag. Push manually:${NC}"
            echo "  git push origin $tag_name"
        fi
    else
        echo ""
        echo "To push the tag:"
        echo "  git push origin $tag_name"
    fi
}

# Update changelog with new version
update_changelog() {
    local version="$1"
    local date=$(date +%Y-%m-%d)

    if [[ ! -f "$CHANGELOG_FILE" ]]; then
        echo -e "${YELLOW}Warning:${NC} CHANGELOG.md not found"
        return
    fi

    # Check if version already in changelog
    if grep -q "## \[$version\]" "$CHANGELOG_FILE"; then
        echo -e "${YELLOW}Version $version already in CHANGELOG.md${NC}"
        return
    fi

    # Add new version entry after [Unreleased]
    local temp_file=$(mktemp)
    awk -v ver="$version" -v dt="$date" '
    /^## \[Unreleased\]/ {
        print
        print ""
        print "## [" ver "] - " dt
        print ""
        print "### Added"
        print "- "
        print ""
        print "### Changed"
        print "- "
        print ""
        print "### Fixed"
        print "- "
        next
    }
    { print }
    ' "$CHANGELOG_FILE" > "$temp_file"

    mv "$temp_file" "$CHANGELOG_FILE"
    echo -e "${GREEN}Updated CHANGELOG.md with version $version${NC}"
    echo -e "${YELLOW}Please edit CHANGELOG.md to add release notes${NC}"
}

# Full release process
do_release() {
    local bump_type="$1"

    echo -e "${BLUE}=== Release Process ===${NC}"
    echo ""

    # Check for uncommitted changes
    if [[ -n $(git status --porcelain) ]]; then
        echo -e "${YELLOW}Warning:${NC} You have uncommitted changes"
        git status --short
        echo ""
        read -p "Continue anyway? [y/N]: " confirm
        if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            echo "Aborted"
            exit 1
        fi
    fi

    local current_version=$(get_version)
    echo -e "Current version: ${CYAN}$current_version${NC}"

    # Bump version
    local new_version=$(bump_version "$bump_type")
    echo -e "New version:     ${GREEN}$new_version${NC}"
    echo ""

    # Update changelog
    update_changelog "$new_version"
    echo ""

    # Show what will be committed
    echo -e "${CYAN}Files to commit:${NC}"
    echo "  - VERSION"
    echo "  - CHANGELOG.md"
    echo ""

    read -p "Commit and tag? [y/N]: " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted. Version file updated but not committed."
        exit 0
    fi

    # Commit version bump
    git add VERSION CHANGELOG.md
    git commit -m "Release v${new_version}"
    echo -e "${GREEN}Committed release v${new_version}${NC}"

    # Push commit
    echo -e "${CYAN}Pushing commit to origin...${NC}"
    if git push origin main; then
        echo -e "${GREEN}Commit pushed!${NC}"
    else
        echo -e "${RED}Failed to push commit${NC}"
        exit 1
    fi

    # Create and push tag
    create_tag "true"

    echo ""
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}  Release v${new_version} Complete!${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "  GitHub Release: https://github.com/devopz-ai/Mac-dev-machine/releases/tag/v${new_version}"
    echo ""
    echo "  Next steps:"
    echo "    1. Go to GitHub Releases page"
    echo "    2. Click 'Draft a new release' or edit the tag"
    echo "    3. Add release notes from CHANGELOG.md"
    echo ""
}

# Show help
show_help() {
    cat << 'EOF'
Mac Dev Machine - Version Management

Usage: ./scripts/version.sh [OPTIONS]

Options:
    (no args)           Show current version
    --bump <type>       Bump version (major, minor, patch)
    --set <version>     Set specific version (e.g., 2.0.0)
    --tag               Create git tag for current version (local only)
    --tag-push          Create git tag and push to GitHub
    --release <type>    Full release: bump, commit, tag, push to GitHub
    --help, -h          Show this help

Examples:
    ./scripts/version.sh                    # Show current version
    ./scripts/version.sh --bump patch       # 1.0.0 -> 1.0.1
    ./scripts/version.sh --bump minor       # 1.0.0 -> 1.1.0
    ./scripts/version.sh --bump major       # 1.0.0 -> 2.0.0
    ./scripts/version.sh --set 2.0.0        # Set to 2.0.0
    ./scripts/version.sh --tag              # Create v1.0.0 tag
    ./scripts/version.sh --release patch    # Full release process

Semantic Versioning:
    MAJOR - Breaking/incompatible changes
    MINOR - New features (backwards compatible)
    PATCH - Bug fixes (backwards compatible)

EOF
}

# Show version info
show_version_info() {
    local version=$(get_version)
    local git_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "none")
    local git_commit=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")
    local git_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")

    echo ""
    echo -e "${BLUE}Mac Dev Machine${NC}"
    echo -e "${BLUE}===============${NC}"
    echo ""
    echo -e "  Version:    ${GREEN}$version${NC}"
    echo -e "  Git Tag:    $git_tag"
    echo -e "  Commit:     $git_commit"
    echo -e "  Branch:     $git_branch"
    echo ""
    echo -e "  Version file: $VERSION_FILE"
    echo ""
}

# Main
main() {
    case "${1:-}" in
        --bump|-b)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error:${NC} Bump type required (major, minor, patch)"
                exit 1
            fi
            bump_version "$2"
            ;;
        --set|-s)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error:${NC} Version required"
                exit 1
            fi
            set_version "$2"
            ;;
        --tag|-t)
            create_tag "false"
            ;;
        --tag-push)
            create_tag "true"
            ;;
        --release|-r)
            if [[ -z "${2:-}" ]]; then
                echo -e "${RED}Error:${NC} Bump type required (major, minor, patch)"
                exit 1
            fi
            do_release "$2"
            ;;
        --help|-h)
            show_help
            ;;
        "")
            show_version_info
            ;;
        *)
            echo -e "${RED}Error:${NC} Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
}

main "$@"
