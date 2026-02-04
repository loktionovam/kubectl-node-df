APP ?= kubectl-node-df
PREFIX ?= $(HOME)/.local
BINDIR ?= $(PREFIX)/bin
INSTALL ?= install

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
		"  install   Install $(APP) to $(BINDIR)" \
		"  uninstall Remove $(APP) from $(BINDIR)"
