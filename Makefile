default: test

test:
	mkdir -p workdir
	PERL5OPT="$(PERL5OPT) -MDevel::Cover" \
	./get_kernel --dir=workdir            \
		--load-plugins=download,unpack,defconfig,prepare,compile

.PHONY: default test
