ERIGON_SUBMODULE=erigon

submodules:
	echo "setting up submodules..."
	git submodule update --init --remote

build:
	mkdir -p $(ERIGON_SUBMODULE)/build/bin
	(cd $(ERIGON_SUBMODULE) && make evm-dbg)
	mv $(ERIGON_SUBMODULE)/build/bin/evm plugins/
