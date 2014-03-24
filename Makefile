UNAME := $(shell uname)
ifndef ARCH
  ARCH := $(shell uname -m)
endif

ifeq ($(UNAME), Darwin)	# OS X
  JAVA_HOME=$(shell /usr/libexec/java_home)
  OPENSSL_CONFIG=./Configure darwin64-x86_64-cc
  ARCH=x86_64
else ifeq ($(OS) $(ARCH), Windows_NT x86_64)		# Windows 64bit
  OPENSSL_CONFIG=./Configure mingw64
  ARCH=x86_64
else ifeq ($(OS) $(ARCH), Windows_NT x86)			# Windows 32bit
  OPENSSL_CONFIG=./Configure mingw
  ARCH=x86
else ifeq ($(ARCH), x86_64)		# anything other 64bit
  OPENSSL_CONFIG=./config
  ARCH=x86_64
else
  OPENSSL_CONFIG=./config
  ARCH=x86
endif


avian: expat fdlibm icu4c openssl
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch)
	(cd avian && make JAVA_HOME="$(JAVA_HOME)" arch=$(ARCH) android=$$(pwd)/../android)

expat:
	(cd android/external/expat \
	    && dos2unix expat_config.h.in \
		&& ./configure --enable-static && make)

fdlibm:
	(cd android/external/fdlibm && (mv makefile.in Makefile.in || true) \
	    && CFLAGS=-fPIC bash configure && make)
icu4c:
	(cd android/external/icu4c; \
	   patch -p1 -N < ../../../patch/icu4c_common_umutex.h.osx.patch; \
	   dos2unix Makefile.in \
	   && ./configure --enable-static && make)
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
	           do patch -p1 -N < ../external/openssl/patches/$$x.patch; done); \
	   dos2unix Makefile.org \
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
