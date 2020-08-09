.PHONY: watch
watch:
	watchexec -e sh,Dockerfile -- docker build -t arch-aarch64-image-builder .

.PHONY: build
build:
	docker run -it --rm -v "$(pwd):/work" arch-aarch64-image-builder