#!/usr/bin/env bash
set -euo pipefail

# ─── Configuration ───────────────────────────────────────────────────────────
APP_NAME="nodeBar"
BUNDLE_NAME="${APP_NAME}.app"
DMG_NAME="${APP_NAME}.dmg"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
APP_DIR="${BUILD_DIR}/${BUNDLE_NAME}"
RESOURCES_DIR="${PROJECT_DIR}/Sources/Resources"
LOGO_SVG="${PROJECT_DIR}/logo.svg"

# ─── Helper ──────────────────────────────────────────────────────────────────
info()  { printf "\033[1;34m==>\033[0m %s\n" "$*"; }
error() { printf "\033[1;31mError:\033[0m %s\n" "$*" >&2; exit 1; }

# ─── Step 1: Generate AppIcon.icns from logo.svg ────────────────────────────
generate_icns() {
    info "Generating AppIcon.icns from logo.svg"

    [ -f "${LOGO_SVG}" ] || error "logo.svg not found at ${LOGO_SVG}"

    local ICONSET_DIR="${BUILD_DIR}/AppIcon.iconset"
    rm -rf "${ICONSET_DIR}"
    mkdir -p "${ICONSET_DIR}"

    # Render a large master PNG from the SVG using sips
    # sips can't read SVG directly, so we use qlmanage (Quick Look) to render it
    local MASTER_PNG="${BUILD_DIR}/icon_master_1024.png"

    # Try qlmanage first (renders SVG to PNG), fall back to sips if it fails
    if command -v qlmanage &>/dev/null; then
        qlmanage -t -s 1024 -o "${BUILD_DIR}" "${LOGO_SVG}" &>/dev/null
        # qlmanage outputs as logo.svg.png
        local QL_OUTPUT="${BUILD_DIR}/logo.svg.png"
        if [ -f "${QL_OUTPUT}" ]; then
            mv "${QL_OUTPUT}" "${MASTER_PNG}"
        else
            error "qlmanage failed to render SVG. Ensure logo.svg is a valid SVG file."
        fi
    else
        error "qlmanage not found. Cannot convert SVG to PNG."
    fi

    # Generate all required icon sizes
    # macOS .iconset requires specific filenames at specific sizes
    local sizes=(16 32 128 256 512)
    for size in "${sizes[@]}"; do
        local double=$((size * 2))
        sips -z "${size}" "${size}" "${MASTER_PNG}" --out "${ICONSET_DIR}/icon_${size}x${size}.png" &>/dev/null
        sips -z "${double}" "${double}" "${MASTER_PNG}" --out "${ICONSET_DIR}/icon_${size}x${size}@2x.png" &>/dev/null
    done

    # Build the .icns file
    iconutil -c icns "${ICONSET_DIR}" -o "${RESOURCES_DIR}/AppIcon.icns"
    rm -rf "${ICONSET_DIR}" "${MASTER_PNG}"

    info "AppIcon.icns created at ${RESOURCES_DIR}/AppIcon.icns"
}

# ─── Step 2: Build the release binary ───────────────────────────────────────
build_binary() {
    info "Building release binary"
    cd "${PROJECT_DIR}"
    swift build -c release 2>&1 | tail -5
    info "Build complete"
}

# ─── Step 3: Assemble the .app bundle ───────────────────────────────────────
assemble_app() {
    info "Assembling ${BUNDLE_NAME}"

    rm -rf "${APP_DIR}"
    mkdir -p "${APP_DIR}/Contents/MacOS"
    mkdir -p "${APP_DIR}/Contents/Resources"

    # Copy Info.plist
    cp "${RESOURCES_DIR}/Info.plist" "${APP_DIR}/Contents/Info.plist"

    # Copy the release binary
    local BINARY
    BINARY="$(swift build -c release --show-bin-path)/${APP_NAME}"
    [ -f "${BINARY}" ] || error "Release binary not found at ${BINARY}"
    cp "${BINARY}" "${APP_DIR}/Contents/MacOS/${APP_NAME}"

    # Copy the icon
    if [ -f "${RESOURCES_DIR}/AppIcon.icns" ]; then
        cp "${RESOURCES_DIR}/AppIcon.icns" "${APP_DIR}/Contents/Resources/AppIcon.icns"
    else
        info "Warning: AppIcon.icns not found, app will use default icon"
    fi

    info "${BUNDLE_NAME} assembled at ${APP_DIR}"
}

# ─── Step 4: Ad-hoc codesign ────────────────────────────────────────────────
codesign_app() {
    info "Ad-hoc code signing ${BUNDLE_NAME}"
    codesign --force --deep -s - "${APP_DIR}"
    info "Code signing complete"
}

# ─── Step 5: Create the DMG ─────────────────────────────────────────────────
create_dmg() {
    info "Creating ${DMG_NAME}"

    local DMG_PATH="${BUILD_DIR}/${DMG_NAME}"
    local DMG_STAGING="${BUILD_DIR}/dmg-staging"

    # Clean up any previous artifacts
    rm -f "${DMG_PATH}"
    rm -rf "${DMG_STAGING}"

    # Create staging area with .app and Applications symlink
    mkdir -p "${DMG_STAGING}"
    cp -R "${APP_DIR}" "${DMG_STAGING}/"
    ln -s /Applications "${DMG_STAGING}/Applications"

    # Create the DMG
    hdiutil create \
        -volname "${APP_NAME}" \
        -srcfolder "${DMG_STAGING}" \
        -ov \
        -format UDZO \
        "${DMG_PATH}" \
        &>/dev/null

    rm -rf "${DMG_STAGING}"

    info "DMG created at ${DMG_PATH}"
    echo ""
    echo "  ${DMG_PATH}"
    echo ""
    info "Done! Mount the DMG and drag ${APP_NAME} to Applications."
}

# ─── Main ────────────────────────────────────────────────────────────────────
main() {
    mkdir -p "${BUILD_DIR}"

    generate_icns
    build_binary
    assemble_app
    codesign_app
    create_dmg
}

main "$@"
