avian: expat fdlibm icu4c openssl
	(cd avian && make android=$$(pwd)/../android)

expat:
	(cd android/external/expat && ./configure --enable-static && make)

fdlibm:
	(cd android/external/fdlibm && (mv makefile.in Makefile.in || true) \
	    && CFLAGS=-fPIC bash configure && make)
icu4c:
	(cd android/external/icu4c && CFLAGS=-fPIC CXXFLAGS=-fPIC ./configure \
	   --enable-static && make)
openssl:
	(cd android/openssl-upstream \
	   && (for x in \
	           progs \
	           handshake_cutthrough \
	           jsse \
	           channelid \
	           eng_dyn_dirs \
	           fix_clang_build \
	           tls12_digests \
	           alpn; \
	           do patch -p1 < ../external/openssl/patches/$$x.patch; done) \
	   && ./Configure darwin64-x86_64-cc && make)