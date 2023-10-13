#######################
### Virtual environment
#######################

.PHONY: help
help:
	@grep -E '^[/a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-17s\033[0m %s\n", $$1, $$2}'


####################
### Docker
####################

.PHONY: docker/build
docker/build: ## Build docker file with service reqs for local development
	docker build -t postgres-backup  .
