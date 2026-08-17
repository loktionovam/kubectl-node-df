APP ?= kubectl-node_df
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
INSTALL ?= install
SHELLCHECK ?= shellcheck

.PHONY: check
check: lint test

.PHONY: lint
lint:
	sh -n $(APP) tests/test.sh tests/fixtures/kubectl
	bash -n tests/smoke.sh
	$(SHELLCHECK) -s sh $(APP) tests/test.sh tests/fixtures/kubectl
	$(SHELLCHECK) -s bash tests/smoke.sh

.PHONY: test
test:
	./tests/test.sh

.PHONY: smoke
smoke:
	./tests/smoke.sh

.PHONY: install
install:
	$(INSTALL) -d $(BINDIR)
	$(INSTALL) -m 0755 $(APP) $(BINDIR)/$(APP)
	@echo "Installed $(BINDIR)/$(APP)"

.PHONY: uninstall
uninstall:
	rm -f $(BINDIR)/$(APP)
	@echo "Removed $(BINDIR)/$(APP)"

.PHONY: help
help:
	@printf "%s\n" \
		"Targets:" \
		"  check     Run lint and tests" \
		"  lint      Run syntax checks and ShellCheck" \
		"  test      Run functional tests" \
		"  smoke     Run tests against the active Kubernetes cluster" \
		"  install   Install $(APP) to $(BINDIR)" \
		"  uninstall Remove $(APP) from $(BINDIR)"
