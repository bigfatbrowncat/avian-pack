UNAME := $(shell uname)
ifndef ARCH
  ARCH := $(shell uname -m)
endif

ifeq ($(UNAME), Darwin)	# OS X
  JAVA_HOME = $(shell /usr/libexec/java_home)
  OPENSSL_CONFIG=./Configure darwin64-x86_64-cc
else ifeq ($(OS) $(ARCH), Windows_NT x86_64)		# Windows 64bit
  OPENSSL_CONFIG=./Configure mingw64
else 												# anything other
  OPENSSL_CONFIG=./config
endif


avian: expat fdlibm icu4c openssl
	(cd avian && make android=$$(pwd)/../android)

expat:
	(cd android/external/expat && ./configure --enable-static && make)

fdlibm:
	(cd android/external/fdlibm && (mv makefile.in Makefile.in || true) \
	    && CFLAGS=-fPIC bash configure && make)
icu4c:
	(cd android/external/icu4c && ./configure \
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
	   && $(OPENSSL_CONFIG) && make)

clean: avian-clean fdlibm-clean icu4c-clean openssl-clean

avian-clean:
	(cd avian; make clean)
	
expat-clean:
	(cd android/external/expat; make clean)

fdlibm-clean:
	(cd android/external/fdlibm; make clean)

icu4c-clean:
	(cd android/external/icu4c; make clean)

openssl-clean:
	(cd android/openssl-upstream; make clean)
