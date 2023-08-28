##@ General

.PHONY: help
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Linting

.PHONE: spell
spell: ## Run cspell on project
	cspell lint lib/**/*.ex lib/*.ex
	cspell lint test/**/*.exs
	cspell lint *.md

.PHONY: lint
lint: export TUCAN_DEV=true
lint: ## Lint tucan
	mix compile --force --warnings-as-errors
	mix format --check-formatted
	mix credo --strict
	mix doctor --failed
	mix dialyzer --format dialyxir
	mix docs -f html
	mix test --warnings-as-errors --cover