TAG=android-uiautomator-server-builder:0.0.1
UID := $(shell id -u)
GID := $(shell id -g)

.PHONY: docker build

docker:
	docker build --target final -t $(TAG) .

build:
	docker run --rm -it \
		--name android-uiautomator-server-builder \
		-e USER_ID=$(UID) \
		-e GROUP_ID=$(GID) \
		-v $(PWD):/home/user/project \
		$(TAG) bash
