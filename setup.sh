#!/bin/bash

# ============================================================
# Mergewello Technologies - Project Scaffolding Script
# ============================================================
#
# Interactive usage (recommended):
#   curl -fsSL <YOUR_RAW_GIST_URL> -o setup.sh && bash setup.sh
#
# Direct usage (skip prompts):
#   ./setup-mergewello.sh <project-name> [--sanity] [--repo <github-url>]
#
# ============================================================

set -e

# ── Make self executable (in case downloaded without +x) ─────

if [[ ! -x "$0" ]]; then
  chmod +x "$0"
fi

# ── Colors ───────────────────────────────────────────────────

CYAN='\033[0;36m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
RED='\033[0;31m'
WHITE='\033[1;37m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

step()  { echo -e "\n${CYAN}>> $1${NC}"; }
ok()    { echo -e "   ${GREEN}OK:${NC} $1"; }
skip()  { echo -e "   ${YELLOW}SKIP:${NC} $1"; }
fail()  { echo -e "   ${RED}FAIL:${NC} $1"; exit 1; }
warn()  { echo -e "   ${YELLOW}WARN:${NC} $1"; }

# ── Parse arguments ──────────────────────────────────────────

PROJECT_NAME=""
GITHUB_REPO=""
INCLUDE_SANITY=false
INTERACTIVE=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --sanity)
      INCLUDE_SANITY=true
      shift
      ;;
    --repo)
      GITHUB_REPO="$2"
      shift 2
      ;;
    -*)
      fail "Unknown flag: $1"
      ;;
    *)
      if [[ -z "$PROJECT_NAME" ]]; then
        PROJECT_NAME="$1"
      else
        fail "Unexpected argument: $1"
      fi
      shift
      ;;
  esac
done

# ── Interactive mode (if no project name passed) ─────────────

if [[ -z "$PROJECT_NAME" ]]; then
  INTERACTIVE=true

  echo ""
  echo -e "${WHITE}=============================================${NC}"
  echo -e "${CYAN}  MERGEWELLO PROJECT SETUP${NC}"
  echo -e "${DIM}  Interactive Mode${NC}"
  echo -e "${WHITE}=============================================${NC}"
  echo ""

  # Project name
  while true; do
    read -rp "$(echo -e "${BOLD}Project name:${NC} ")" RAW_NAME

    if [[ -z "$RAW_NAME" ]]; then
      echo -e "${RED}  Project name cannot be empty.${NC}"
      continue
    fi

    # Sanitize: lowercase, replace spaces with hyphens, remove special chars
    PROJECT_NAME=$(echo "$RAW_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/[^a-z0-9-]//g')
    echo -e "${DIM}  Folder name: ${PROJECT_NAME}${NC}"

    if [[ -d "$PROJECT_NAME" ]]; then
      echo -e "${RED}  Folder '${PROJECT_NAME}' already exists. Choose a different name.${NC}"
      PROJECT_NAME=""
      continue
    fi

    break
  done

  echo ""

  # Include Sanity?
  read -rp "$(echo -e "${BOLD}Include Sanity CMS? [y/N]:${NC} ")" SANITY_ANSWER
  case "$SANITY_ANSWER" in
    [yY]|[yY][eE][sS])
      INCLUDE_SANITY=true
      echo -e "${DIM}  Sanity CMS will be included${NC}"
      ;;
    *)
      INCLUDE_SANITY=false
      echo -e "${DIM}  No CMS - Starter package${NC}"
      ;;
  esac

  echo ""

  # GitHub repo?
  read -rp "$(echo -e "${BOLD}GitHub repo URL ${DIM}(leave blank to skip)${NC}${BOLD}:${NC} ")" GITHUB_REPO
  if [[ -n "$GITHUB_REPO" ]]; then
    echo -e "${DIM}  Will push to: ${GITHUB_REPO}${NC}"
  else
    echo -e "${DIM}  Skipping GitHub - you can connect later${NC}"
  fi

  echo ""

  # Confirm
  STACK="Astro + Tailwind"
  if [[ "$INCLUDE_SANITY" == true ]]; then
    STACK="Astro + Tailwind + Sanity"
  fi

  echo -e "${WHITE}─────────────────────────────────────────────${NC}"
  echo -e "  ${WHITE}Project:  ${CYAN}${PROJECT_NAME}${NC}"
  echo -e "  ${WHITE}Stack:    ${CYAN}${STACK}${NC}"
  if [[ -n "$GITHUB_REPO" ]]; then
    echo -e "  ${WHITE}Repo:     ${CYAN}${GITHUB_REPO}${NC}"
  fi
  echo -e "${WHITE}─────────────────────────────────────────────${NC}"
  echo ""

  read -rp "$(echo -e "${BOLD}Proceed? [Y/n]:${NC} ")" CONFIRM
  case "$CONFIRM" in
    [nN]|[nN][oO])
      echo -e "${YELLOW}Setup cancelled.${NC}"
      exit 0
      ;;
  esac
fi

# ── Banner (non-interactive mode) ────────────────────────────

if [[ "$INTERACTIVE" == false ]]; then
  echo ""
  echo -e "${WHITE}=============================================${NC}"
  echo -e "${CYAN}  MERGEWELLO PROJECT SETUP${NC}"
  echo -e "${WHITE}  Project: ${PROJECT_NAME}${NC}"
  echo -e "${WHITE}=============================================${NC}"
fi

# ── Pre-flight checks ───────────────────────────────────────

step "Running pre-flight checks"

command -v node >/dev/null 2>&1 || fail "Node.js is not installed"
command -v npm >/dev/null 2>&1  || fail "npm is not installed"
command -v git >/dev/null 2>&1  || fail "Git is not installed"

NODE_VERSION=$(node -v | sed 's/v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)

if [[ "$NODE_MAJOR" -lt 18 ]]; then
  fail "Node.js 18+ required. You have v${NODE_VERSION}."
fi
ok "Node.js v${NODE_VERSION}"

if [[ -d "$PROJECT_NAME" ]]; then
  fail "Folder '${PROJECT_NAME}' already exists. Delete it or use a different name."
fi
ok "All checks passed"

# ── Create Astro project ────────────────────────────────────

step "Creating Astro project"
npm create astro@latest "$PROJECT_NAME" -- --template minimal --install --yes

if [[ ! -d "$PROJECT_NAME" ]]; then
  fail "Astro project creation failed."
fi
ok "Astro project created"

cd "$PROJECT_NAME"

# ── Git identity (local only) ───────────────────────────────

step "Configuring Git"

if [[ ! -d ".git" ]]; then
  git init > /dev/null 2>&1
fi

git config user.name "Mergewello Technologies"
git config user.email "contact@mergewello.com"
ok "Local Git identity set"

# ── Tailwind CSS ─────────────────────────────────────────────

step "Adding Tailwind CSS"
npx astro add tailwind --yes

if [[ $? -ne 0 ]]; then
  fail "Tailwind installation failed."
fi
ok "Tailwind CSS integrated"

# ── Sanity (optional) ───────────────────────────────────────

if [[ "$INCLUDE_SANITY" == true ]]; then
  step "Adding Sanity CMS integration"
  npm install @sanity/client @sanity/image-url

  if [[ $? -ne 0 ]]; then
    fail "Sanity packages failed to install."
  fi
  ok "Sanity client packages installed"
else
  skip "Sanity CMS"
fi

# ── Scaffold folder structure ────────────────────────────────

step "Scaffolding project structure"

FOLDERS=(
  "src/components/ui"
  "src/components/sections"
  "src/layouts"
  "src/styles"
  "src/lib"
  "src/content"
  "src/assets/images"
  "public/fonts"
)

for folder in "${FOLDERS[@]}"; do
  mkdir -p "$folder"
done
ok "Folder structure created"

# ── Base layout ──────────────────────────────────────────────

step "Creating base files"

cat > src/layouts/BaseLayout.astro << 'EOF'
---
interface Props {
  title: string;
  description?: string;
}

const {
  title,
  description = "Built by Mergewello Technologies"
} = Astro.props;
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <meta name="description" content={description} />
    <meta name="generator" content={Astro.generator} />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <title>{title}</title>
  </head>
  <body class="min-h-screen bg-white text-gray-900 antialiased">
    <slot />
  </body>
</html>
EOF
ok "BaseLayout.astro"

# Global CSS
cat > src/styles/global.css << 'EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  html {
    scroll-behavior: smooth;
    -webkit-font-smoothing: antialiased;
  }
}
EOF
ok "global.css"

# Sanity client (if included)
if [[ "$INCLUDE_SANITY" == true ]]; then
cat > src/lib/sanity.ts << 'EOF'
import { createClient } from "@sanity/client";
import imageUrlBuilder from "@sanity/image-url";

export const client = createClient({
  projectId: import.meta.env.PUBLIC_SANITY_PROJECT_ID,
  dataset: import.meta.env.PUBLIC_SANITY_DATASET || "production",
  apiVersion: "2024-01-01",
  useCdn: true,
});

const builder = imageUrlBuilder(client);

export function urlFor(source: any) {
  return builder.image(source);
}
EOF
ok "sanity.ts client"
fi

# .env template
cat > .env.example << EOF
# ============================================
# Mergewello Project: ${PROJECT_NAME}
# ============================================

# Sanity CMS (fill in when connecting)
PUBLIC_SANITY_PROJECT_ID=
PUBLIC_SANITY_DATASET=production

# Site
PUBLIC_SITE_URL=
EOF

cp .env.example .env
ok ".env files"

# ── Update .gitignore ────────────────────────────────────────

step "Updating .gitignore"

cat >> .gitignore << 'EOF'

# Mergewello additions
.env
.env.local
.env.*.local
.DS_Store
Thumbs.db
EOF
ok ".gitignore updated"

# ── Replace default index page ───────────────────────────────

cat > src/pages/index.astro << 'EOF'
---
import BaseLayout from "../layouts/BaseLayout.astro";
---

<BaseLayout title="Welcome">
  <main class="flex items-center justify-center min-h-screen">
    <div class="text-center">
      <h1 class="text-4xl font-bold mb-4">Project Ready</h1>
      <p class="text-gray-600">Built with Astro + Tailwind by Mergewello Technologies</p>
    </div>
  </main>
</BaseLayout>
EOF
ok "index.astro replaced"

# ── Initial commit ───────────────────────────────────────────

step "Creating initial commit"

COMMIT_MSG="chore: project scaffold - Astro + Tailwind"
if [[ "$INCLUDE_SANITY" == true ]]; then
  COMMIT_MSG="chore: project scaffold - Astro + Tailwind + Sanity"
fi

git add .
git commit -m "$COMMIT_MSG"

if [[ $? -ne 0 ]]; then
  fail "Commit failed. Check git config."
fi
ok "Initial commit created"

# ── GitHub (optional) ────────────────────────────────────────

if [[ -n "$GITHUB_REPO" ]]; then
  step "Connecting to GitHub"
  git branch -M main
  git remote add origin "$GITHUB_REPO" 2>/dev/null || true
  git push -u origin main

  if [[ $? -ne 0 ]]; then
    warn "Push failed. Check repo access or authentication."
    echo -e "   ${YELLOW}You can push manually later:${NC}"
    echo -e "   ${WHITE}  git remote add origin ${GITHUB_REPO}${NC}"
    echo -e "   ${WHITE}  git push -u origin main${NC}"
  else
    ok "Pushed to ${GITHUB_REPO}"
  fi
else
  skip "GitHub connection"
fi

# ── Summary ──────────────────────────────────────────────────

STACK="Astro + Tailwind"
if [[ "$INCLUDE_SANITY" == true ]]; then
  STACK="Astro + Tailwind + Sanity"
fi

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  SETUP COMPLETE${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "  ${WHITE}Project:   ${PROJECT_NAME}${NC}"
echo -e "  ${WHITE}Stack:     ${STACK}${NC}"
echo -e "  ${WHITE}Location:  $(pwd)${NC}"
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo -e "  ${WHITE}  npm run dev              Start dev server${NC}"

if [[ "$INCLUDE_SANITY" == true ]]; then
  echo -e "  ${WHITE}  nano .env                Add Sanity project ID${NC}"
fi

if [[ -z "$GITHUB_REPO" ]]; then
  echo -e "  ${WHITE}  git remote add origin <url>    Connect to GitHub${NC}"
  echo -e "  ${WHITE}  git push -u origin main        Push your code${NC}"
fi

echo ""
