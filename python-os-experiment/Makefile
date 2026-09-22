PROJECT_ROOT := $(CURDIR)
DISK_IMAGE := $(PROJECT_ROOT)/build/disk.img

.PHONY: create-disk install-app remove-app list-app check-app run clean

create-disk:
	./tools/create-disk.sh

install-app:
	@if [ -z "$(APP)" ]; then \
		echo "Usage: make install-app APP=path/to/program.py"; \
		exit 1; \
	fi
	./tools/install-app.sh "$(APP)"

remove-app:
	./tools/remove-app.sh

list-app:
	./tools/list-app.sh

check-app:
	@if [ -z "$(APP)" ]; then \
		echo "Usage: make check-app APP=path/to/program.py"; \
		exit 1; \
	fi
	./tools/check-app.sh "$(APP)"

run:
	./tools/run-qemu.sh

clean:
	rm -rf build