# ─────────────────────────────────────────────────────────────
#  Devoxx France 2026 — Kafka with KRaft in Production
#  Slides build & serve Makefile
# ─────────────────────────────────────────────────────────────

SHELL    := /bin/bash
PORT     ?= 8000
DIST     := dist
PYTHON   := python3
BROWSER  := open

# Reveal.js CDN base (pinned version)
REVEAL_VERSION := 5.1.0
REVEAL_CDN     := https://cdn.jsdelivr.net/npm/reveal.js@$(REVEAL_VERSION)

# ─── Source files ────────────────────────────────────────────
SLIDES   := $(wildcard *.md)
ASSETS   := index.html styles.css $(wildcard img/*) \
            paxos-animation.html paxos-happy-animation.html \
            raft-animation.html zab-animation.html

# ─── Colors ─────────────────────────────────────────────────
CYAN     := \033[36m
GREEN    := \033[32m
YELLOW   := \033[33m
RED      := \033[31m
RESET    := \033[0m
BOLD     := \033[1m

.DEFAULT_GOAL := help

# ─────────────────────────────────────────────────────────────
#  TARGETS
# ─────────────────────────────────────────────────────────────

.PHONY: help serve open build clean check watch

## help : Show this help message
help:
	@printf "\n"
	@printf "$(BOLD)$(CYAN)╔══════════════════════════════════════════════════════════╗$(RESET)\n"
	@printf "$(BOLD)$(CYAN)║  Devoxx 2026 — Kafka + KRaft Slides                     ║$(RESET)\n"
	@printf "$(BOLD)$(CYAN)╚══════════════════════════════════════════════════════════╝$(RESET)\n"
	@printf "\n"
	@printf "$(BOLD)Usage:$(RESET)  make $(GREEN)<target>$(RESET)\n"
	@printf "\n"
	@printf "$(BOLD)Development:$(RESET)\n"
	@printf "  $(GREEN)serve$(RESET)    Start local dev server on port $(PORT)\n"
	@printf "  $(GREEN)open$(RESET)     Start server and open in browser\n"
	@printf "  $(GREEN)watch$(RESET)    Start server with live-reload (requires fswatch)\n"
	@printf "\n"
	@printf "$(BOLD)Production:$(RESET)\n"
	@printf "  $(GREEN)build$(RESET)    Build self-contained dist/ for deployment\n"
	@printf "  $(GREEN)check$(RESET)    Validate all source files exist\n"
	@printf "  $(GREEN)clean$(RESET)    Remove dist/ directory\n"
	@printf "\n"
	@printf "$(BOLD)Options:$(RESET)\n"
	@printf "  PORT=$(PORT)  — override with: make serve PORT=3000\n"
	@printf "\n"

## serve : Start a local HTTP server (default port 8000)
serve: check
	@printf "$(BOLD)$(GREEN)▶ Serving slides at http://localhost:$(PORT)$(RESET)\n"
	@printf "  Press $(BOLD)Ctrl+C$(RESET) to stop\n\n"
	@$(PYTHON) -m http.server $(PORT)

## open : Start server and open browser
open: check
	@printf "$(BOLD)$(GREEN)▶ Opening slides in browser...$(RESET)\n"
	@$(BROWSER) "http://localhost:$(PORT)" &
	@$(PYTHON) -m http.server $(PORT)

## watch : Start server with auto-reload on file changes (requires fswatch)
watch: check
	@command -v fswatch >/dev/null 2>&1 || { \
		printf "$(RED)✗ fswatch not found. Install with: brew install fswatch$(RESET)\n"; \
		exit 1; \
	}
	@printf "$(BOLD)$(GREEN)▶ Watching for changes... (http://localhost:$(PORT))$(RESET)\n"
	@printf "  Modify any .md, .css, or .html file to trigger reload\n\n"
	@$(PYTHON) -m http.server $(PORT) &
	@SERVER_PID=$$!; \
	trap "kill $$SERVER_PID 2>/dev/null; exit 0" INT TERM; \
	$(BROWSER) "http://localhost:$(PORT)" & \
	fswatch -o *.md *.css *.html | while read; do \
		printf "$(YELLOW)↻ Change detected — reload browser$(RESET)\n"; \
	done; \
	kill $$SERVER_PID 2>/dev/null

## build : Create self-contained production dist/
build: check
	@printf "$(BOLD)$(CYAN)▶ Building production bundle...$(RESET)\n"
	@rm -rf $(DIST)
	@mkdir -p $(DIST)/img
	@printf "  $(GREEN)✓$(RESET) Created $(DIST)/\n"
	@# ── Copy slide markdown ──
	@cp $(SLIDES) $(DIST)/
	@printf "  $(GREEN)✓$(RESET) Copied $(words $(SLIDES)) slide files\n"
	@# ── Copy assets ──
	@cp styles.css $(DIST)/
	@cp paxos-animation.html paxos-happy-animation.html \
	    raft-animation.html zab-animation.html $(DIST)/ 2>/dev/null || true
	@printf "  $(GREEN)✓$(RESET) Copied CSS + animations\n"
	@# ── Copy images ──
	@if [ -d img ] && [ "$$(ls -A img 2>/dev/null)" ]; then \
		cp -r img/* $(DIST)/img/; \
		printf "  $(GREEN)✓$(RESET) Copied images\n"; \
	else \
		printf "  $(YELLOW)⚠$(RESET) No images to copy\n"; \
	fi
	@# ── Download Reveal.js for offline use ──
	@printf "  $(CYAN)↓$(RESET) Downloading Reveal.js $(REVEAL_VERSION) for offline...\n"
	@mkdir -p $(DIST)/vendor/revealjs/dist/theme \
	          $(DIST)/vendor/revealjs/plugin/markdown \
	          $(DIST)/vendor/revealjs/plugin/highlight \
	          $(DIST)/vendor/revealjs/plugin/notes \
	          $(DIST)/vendor/revealjs/plugin/zoom
	@curl -sL --retry 2 $(REVEAL_CDN)/dist/reset.css           -o $(DIST)/vendor/revealjs/dist/reset.css
	@curl -sL --retry 2 $(REVEAL_CDN)/dist/reveal.css           -o $(DIST)/vendor/revealjs/dist/reveal.css
	@curl -sL --retry 2 $(REVEAL_CDN)/dist/reveal.js            -o $(DIST)/vendor/revealjs/dist/reveal.js
	@curl -sL --retry 2 $(REVEAL_CDN)/dist/theme/white.css      -o $(DIST)/vendor/revealjs/dist/theme/white.css
	@curl -sL --retry 2 $(REVEAL_CDN)/plugin/markdown/markdown.js   -o $(DIST)/vendor/revealjs/plugin/markdown/markdown.js
	@curl -sL --retry 2 $(REVEAL_CDN)/plugin/highlight/highlight.js  -o $(DIST)/vendor/revealjs/plugin/highlight/highlight.js
	@curl -sL --retry 2 $(REVEAL_CDN)/plugin/highlight/github.css    -o $(DIST)/vendor/revealjs/plugin/highlight/github.css
	@curl -sL --retry 2 $(REVEAL_CDN)/plugin/notes/notes.js          -o $(DIST)/vendor/revealjs/plugin/notes/notes.js
	@curl -sL --retry 2 $(REVEAL_CDN)/plugin/zoom/zoom.js            -o $(DIST)/vendor/revealjs/plugin/zoom/zoom.js
	@printf "  $(GREEN)✓$(RESET) Downloaded Reveal.js $(REVEAL_VERSION)\n"
	@# ── Rewrite index.html CDN paths → local vendor paths ──
	@sed \
		-e 's|https://cdn.jsdelivr.net/npm/reveal.js@$(REVEAL_VERSION)/dist/|vendor/revealjs/dist/|g' \
		-e 's|https://cdn.jsdelivr.net/npm/reveal.js@$(REVEAL_VERSION)/plugin/|vendor/revealjs/plugin/|g' \
		-e 's|https://cdn.jsdelivr.net/npm/reveal.js@$(REVEAL_VERSION)/|vendor/revealjs/|g' \
		index.html > $(DIST)/index.html
	@printf "  $(GREEN)✓$(RESET) Rewrote CDN → local vendor paths\n"
	@# ── Download Google Fonts CSS for offline ──
	@mkdir -p $(DIST)/vendor/fonts
	@curl -sL --retry 2 "https://fonts.googleapis.com/css2?family=Inter:wght@300;400;600;700;900&family=JetBrains+Mono:wght@400;700&display=swap" \
		-o $(DIST)/vendor/fonts/fonts.css 2>/dev/null && \
		printf "  $(GREEN)✓$(RESET) Downloaded font manifest\n" || \
		printf "  $(YELLOW)⚠$(RESET) Font download skipped (needs internet for fonts)\n"
	@# ── Summary ──
	@printf "\n$(BOLD)$(GREEN)✓ Production build complete!$(RESET)\n\n"
	@TOTAL=$$(find $(DIST) -type f | wc -l | tr -d ' '); \
	SIZE=$$(du -sh $(DIST) | cut -f1); \
	printf "  📁 $(DIST)/  ·  $$TOTAL files  ·  $$SIZE\n\n"
	@printf "  $(BOLD)To serve:$(RESET)  cd $(DIST) && python3 -m http.server 8080\n"
	@printf "  $(BOLD)To deploy:$(RESET) upload $(DIST)/ to any static host\n\n"

## check : Validate all required source files exist
check:
	@MISSING=0; \
	for f in index.html styles.css $(SLIDES); do \
		if [ ! -f "$$f" ]; then \
			printf "$(RED)✗ Missing: $$f$(RESET)\n"; \
			MISSING=$$((MISSING + 1)); \
		fi; \
	done; \
	if [ $$MISSING -gt 0 ]; then \
		printf "$(RED)✗ $$MISSING file(s) missing. Aborting.$(RESET)\n"; \
		exit 1; \
	fi; \
	printf "  $(GREEN)✓$(RESET) All $(words $(SLIDES)) slides + assets present\n"

## clean : Remove the dist/ directory
clean:
	@rm -rf $(DIST)
	@printf "  $(GREEN)✓$(RESET) Cleaned $(DIST)/\n"
