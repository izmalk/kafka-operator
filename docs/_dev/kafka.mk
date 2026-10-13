# Kafka additions to the upstream Sphinx Stack Makefile.
MDFORMAT_DIR     ?= $(DEV_DIR)/mdformat
MDFORMAT_VENVDIR ?= $(MDFORMAT_DIR)/.venv
MDFORMAT_CMD     ?= $(MDFORMAT_VENVDIR)/bin/mdformat
# Staging can override this command to select its copied, not-yet-tracked pages.
MDFORMAT_FILES   ?= git ls-files '*.md'

.PHONY: generate mdformat mdformat-check mdformat-install mdformat-lock clean-mdformat

generate: install
	@. $(DOCS_VENV); python3 $(DEV_DIR)/generate_charm_reference.py
	@. $(DOCS_VENV); python3 $(DEV_DIR)/generate_statuses.py

html run epub pdf linkcheck lint-md: generate

$(MDFORMAT_VENVDIR): $(MDFORMAT_DIR)/requirements.txt
	@echo "... setting up hash-pinned mdformat virtualenv"
	python3 -m venv $(MDFORMAT_VENVDIR)
	$(MDFORMAT_VENVDIR)/bin/pip install $(PIPOPTS) --require-virtualenv \
	    --require-hashes --no-deps -r $(MDFORMAT_DIR)/requirements.txt \
	    --log $(MDFORMAT_VENVDIR)/pip_install.log
	@touch $(MDFORMAT_VENVDIR)

mdformat-install: $(MDFORMAT_VENVDIR)

mdformat: mdformat-install
	@$(MDFORMAT_FILES) | xargs -r $(MDFORMAT_CMD)

mdformat-check: mdformat-install
	@$(MDFORMAT_FILES) | xargs -r $(MDFORMAT_CMD) --check

mdformat-lock:
	@tmpdir=$$(mktemp -d); \
	trap 'rm -rf "$$tmpdir"' EXIT HUP INT TERM; \
	python3 -m venv "$$tmpdir" && \
	"$$tmpdir/bin/pip" install --quiet --upgrade pip pip-tools && \
	"$$tmpdir/bin/pip-compile" --generate-hashes --strip-extras \
	    --header --annotation-style line \
	    --output-file $(MDFORMAT_DIR)/requirements.txt \
	    $(MDFORMAT_DIR)/requirements.in

clean: clean-mdformat
clean-mdformat:
	rm -rf $(MDFORMAT_VENVDIR)