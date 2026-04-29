#!/bin/bash

# ============================================================
# Mergewello Technologies - Project Scaffolding Script
# ============================================================
#
# Interactive usage:
#   curl -fsSL <YOUR_RAW_URL> -o setup.sh && bash setup.sh
#
# Direct usage:
#   ./setup-mergewello.sh <project-name> [--sanity] [--repo <github-url>]
#
# ============================================================

set -e

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

# ── Interactive mode ─────────────────────────────────────────

if [[ -z "$PROJECT_NAME" ]]; then
  INTERACTIVE=true

  echo ""
  echo -e "${WHITE}=============================================${NC}"
  echo -e "${CYAN}  MERGEWELLO PROJECT SETUP${NC}"
  echo -e "${DIM}  Interactive Mode${NC}"
  echo -e "${WHITE}=============================================${NC}"
  echo ""

  while true; do
    read -rp "$(echo -e "${BOLD}Project name:${NC} ")" RAW_NAME

    if [[ -z "$RAW_NAME" ]]; then
      echo -e "${RED}  Project name cannot be empty.${NC}"
      continue
    fi

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

  read -rp "$(echo -e "${BOLD}GitHub repo URL ${DIM}(leave blank to skip)${NC}${BOLD}:${NC} ")" GITHUB_REPO
  if [[ -n "$GITHUB_REPO" ]]; then
    echo -e "${DIM}  Will push to: ${GITHUB_REPO}${NC}"
  else
    echo -e "${DIM}  Skipping GitHub - you can connect later${NC}"
  fi

  echo ""

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

if [[ -d "$PROJECT_NAME" ]]; then
  fail "Folder '${PROJECT_NAME}' already exists. Delete it or use a different name."
fi

ok "Node.js v${NODE_VERSION}"
ok "All checks passed"

# ── Create Astro project ────────────────────────────────────

step "Creating Astro project"
npm create astro@latest "$PROJECT_NAME" -- --template minimal --install --yes

[[ -d "$PROJECT_NAME" ]] || fail "Astro project creation failed."
ok "Astro project created"

cd "$PROJECT_NAME"

# ── Git setup ───────────────────────────────────────────────

step "Configuring Git"

if [[ ! -d ".git" ]]; then
  git init >/dev/null 2>&1
fi

git config user.name "Mergewello Technologies"
git config user.email "contact@mergewello.com"
ok "Local Git identity set"

# ── Tailwind ────────────────────────────────────────────────

step "Adding Tailwind CSS"
npx astro add tailwind --yes >/dev/null 2>&1 || fail "Tailwind installation failed."
ok "Tailwind CSS integrated"

# ── Sanity packages (optional) ──────────────────────────────

if [[ "$INCLUDE_SANITY" == true ]]; then
  step "Adding Sanity CMS packages"
  npm install @sanity/client @sanity/image-url >/dev/null 2>&1 || fail "Sanity packages failed to install."
  ok "Sanity client packages installed"
else
  skip "Sanity CMS"
fi

# ── Folder structure ────────────────────────────────────────

step "Scaffolding project structure"

FOLDERS=(
  "src/components/ui"
  "src/components/sections"
  "src/layouts"
  "src/lib"
  "src/styles"
  "src/assets/images"
  "public/fonts"
)

for folder in "${FOLDERS[@]}"; do
  mkdir -p "$folder"
done

ok "Folder structure created"

# ── Base files ──────────────────────────────────────────────

step "Creating base files"

cat > src/lib/site.ts << 'EOF'
export const siteConfig = {
  name: "Mergewello Technologies",
  siteUrl: "",
  defaultTitle: "Fast & Modern Websites for Your Business",
  description:
    "Mergewello Technologies builds fast, modern websites for growing businesses.",
  ogImage: "/og-image.jpg",
};
EOF
ok "site.ts"

cat > src/components/ui/Container.astro << 'EOF'
<div class="mx-auto w-full max-w-6xl px-4 sm:px-6 lg:px-8">
  <slot />
</div>
EOF
ok "Container.astro"

cat > src/components/ui/Section.astro << 'EOF'
---
interface Props {
  class?: string;
}
const { class: className = "" } = Astro.props;
---

<section class={`py-16 md:py-20 ${className}`}>
  <slot />
</section>
EOF
ok "Section.astro"

cat > src/components/ui/Button.astro << 'EOF'
---
interface Props {
  href?: string;
  variant?: "primary" | "secondary";
  class?: string;
}
const {
  href = "#",
  variant = "primary",
  class: className = "",
} = Astro.props;

const base =
  "inline-flex items-center justify-center rounded-lg px-6 py-3 text-sm font-semibold transition";
const styles =
  variant === "primary"
    ? "bg-black text-white hover:opacity-90"
    : "bg-gray-100 text-gray-900 hover:bg-gray-200";
---

<a href={href} class={`${base} ${styles} ${className}`}>
  <slot />
</a>
EOF
ok "Button.astro"

cat > src/components/ui/StructuredData.astro << 'EOF'
---
const websiteData = {
  "@context": "https://schema.org",
  "@type": "WebSite",
  name: "Mergewello Technologies",
  url: "https://example.com"
};
---

<script type="application/ld+json" set:html={JSON.stringify(websiteData)} />
EOF
ok "StructuredData.astro"

cat > src/components/ui/Analytics.astro << 'EOF'
---
/*
  Placeholder for analytics scripts.
  Add GA, Plausible, or other analytics here when needed.
*/
---
EOF
ok "Analytics.astro"

cat > src/styles/global.css << 'EOF'
@import "tailwindcss";

@layer base {
  html {
    scroll-behavior: smooth;
    -webkit-font-smoothing: antialiased;
  }

  body {
    @apply bg-white text-gray-900;
  }
}
EOF
ok "global.css"

cat > src/layouts/BaseLayout.astro << 'EOF'
---
import "../styles/global.css";
import StructuredData from "../components/ui/StructuredData.astro";
import Analytics from "../components/ui/Analytics.astro";
import { siteConfig } from "../lib/site";

interface Props {
  title?: string;
  description?: string;
  noindex?: boolean;
}

const {
  title = siteConfig.defaultTitle,
  description = siteConfig.description,
  noindex = false,
} = Astro.props;

const siteUrl = siteConfig.siteUrl || "https://example.com";
const canonicalUrl = `${siteUrl}${Astro.url.pathname}`;
const pageTitle = `${title} | ${siteConfig.name}`;
const ogImage = `${siteUrl}${siteConfig.ogImage}`;
---

<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />

    <title>{pageTitle}</title>
    <meta name="description" content={description} />
    <meta name="author" content={siteConfig.name} />
    <link rel="canonical" href={canonicalUrl} />

    {noindex ? (
      <meta name="robots" content="noindex, nofollow" />
    ) : (
      <meta name="robots" content="index, follow" />
    )}

    <meta property="og:title" content={pageTitle} />
    <meta property="og:description" content={description} />
    <meta property="og:image" content={ogImage} />
    <meta property="og:url" content={canonicalUrl} />
    <meta property="og:type" content="website" />
    <meta property="og:site_name" content={siteConfig.name} />

    <meta name="twitter:card" content="summary_large_image" />
    <meta name="twitter:title" content={pageTitle} />
    <meta name="twitter:description" content={description} />
    <meta name="twitter:image" content={ogImage} />

    <meta name="generator" content={Astro.generator} />
    <link rel="icon" href="/favicon.svg" type="image/svg+xml" />

    <StructuredData />
    <Analytics />
  </head>
  <body class="min-h-screen antialiased">
    <slot />
  </body>
</html>
EOF
ok "BaseLayout.astro"

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
  ok "sanity.ts"
fi

cat > .env.example << EOF
# ============================================
# Mergewello Project: ${PROJECT_NAME}
# ============================================

PUBLIC_SITE_URL=
PUBLIC_SANITY_PROJECT_ID=
PUBLIC_SANITY_DATASET=production
EOF

cp .env.example .env
ok ".env.example and .env"

# ── Improve .gitignore ──────────────────────────────────────

step "Updating .gitignore"

cat >> .gitignore << 'EOF'

# Mergewello additions
.env
.env.local
.env.*.local
.DS_Store
Thumbs.db
.vercel
dist
EOF
ok ".gitignore updated"

# ── Replace starter page ────────────────────────────────────

cat > src/pages/index.astro << 'EOF'
---
import BaseLayout from "../layouts/BaseLayout.astro";
import Container from "../components/ui/Container.astro";
import Section from "../components/ui/Section.astro";
import Button from "../components/ui/Button.astro";
---

<BaseLayout title="Project Ready">
  <Section class="min-h-screen flex items-center">
    <Container>
      <div class="mx-auto max-w-3xl text-center">
        <p class="mb-4 text-sm font-medium uppercase tracking-wide text-gray-500">
          Mergewello Project Scaffold
        </p>
        <h1 class="text-4xl font-bold tracking-tight sm:text-5xl">
          Your project is ready to build
        </h1>
        <p class="mt-6 text-lg text-gray-600">
          Start building with Astro, Tailwind, and a reusable Mergewello structure.
        </p>
        <div class="mt-8 flex justify-center">
          <Button href="#">Start Building</Button>
        </div>
      </div>
    </Container>
  </Section>
</BaseLayout>
EOF
ok "Starter homepage created"

# ── Initial commit ──────────────────────────────────────────

step "Creating initial commit"

COMMIT_MSG="chore: scaffold Astro + Tailwind"
if [[ "$INCLUDE_SANITY" == true ]]; then
  COMMIT_MSG="chore: scaffold Astro + Tailwind + Sanity"
fi

git add .
git commit -m "$COMMIT_MSG" >/dev/null 2>&1 || fail "Commit failed. Check git config."
ok "Initial commit created"

# ── Optional GitHub push ────────────────────────────────────

if [[ -n "$GITHUB_REPO" ]]; then
  step "Connecting to GitHub"
  git branch -M main
  git remote add origin "$GITHUB_REPO" 2>/dev/null || true

  if git push -u origin main; then
    ok "Pushed to ${GITHUB_REPO}"
  else
    warn "Push failed. Check repo access or authentication."
    echo -e "   ${YELLOW}You can push manually later:${NC}"
    echo -e "   ${WHITE}  git remote add origin ${GITHUB_REPO}${NC}"
    echo -e "   ${WHITE}  git push -u origin main${NC}"
  fi
else
  skip "GitHub connection"
fi

# ── Summary ─────────────────────────────────────────────────

STACK="Astro + Tailwind"
MODE="Starter (static)"
if [[ "$INCLUDE_SANITY" == true ]]; then
  STACK="Astro + Tailwind + Sanity"
  MODE="Growth / Full (CMS-ready)"
fi

echo ""
echo -e "${GREEN}=============================================${NC}"
echo -e "${GREEN}  SETUP COMPLETE${NC}"
echo -e "${GREEN}=============================================${NC}"
echo ""
echo -e "  ${WHITE}Project:   ${PROJECT_NAME}${NC}"
echo -e "  ${WHITE}Stack:     ${STACK}${NC}"
echo -e "  ${WHITE}Mode:      ${MODE}${NC}"
echo -e "  ${WHITE}Location:  $(pwd)${NC}"
echo ""
echo -e "  ${CYAN}Next steps:${NC}"
echo -e "  ${WHITE}  npm run dev${NC}              Start dev server"
echo -e "  ${WHITE}  edit src/lib/site.ts${NC}     Set site metadata"

if [[ "$INCLUDE_SANITY" == true ]]; then
  echo -e "  ${WHITE}  edit .env${NC}                Add Sanity project ID"
fi

if [[ -z "$GITHUB_REPO" ]]; then
  echo -e "  ${WHITE}  git remote add origin <url>${NC}"
  echo -e "  ${WHITE}  git push -u origin main${NC}"
fi

echo ""
