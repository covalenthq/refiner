ERIGON_SUBMODULE=erigon

submodules:
	echo "setting up submodules..."
	git submodule update --init --remote

build:
	mkdir -p $(ERIGON_SUBMODULE)/build/bin
	(cd $(ERIGON_SUBMODULE) && make evm-prod)
	cp $(ERIGON_SUBMODULE)/build/bin/evm plugins/evm
