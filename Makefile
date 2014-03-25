UNAME := $(shell uname)
ifndef ARCH
  ARCH := $(shell uname -m)
endif

ifeq ($(UNAME), Darwin)	# OS X
  JAVA_HOME=$(shell /usr/libexec/java_home)
  OPENSSL_CONFIG=./Configure darwin64-x86_64-cc
  PLATFORM=osx
else ifeq ($(OS) $(ARCH), Windows_NT x86_64)		# Windows 64bit
  OPENSSL_CONFIG=./Configure mingw64
  PLATFORM=windows
else ifeq ($(OS) $(ARCH), Windows_NT i686)			# Windows 32bit
  OPENSSL_CONFIG=./Configure mingw
  ARCH=i386
  PLATFORM=windows
else
  OPENSSL_CONFIG=./config
  PLATFORM=unknown
endif

avian: expat fdlibm icu4c openssl
ifeq ($(PLATFORM), windows)
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch || true)
endif
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(ARCH) android=$$(pwd)/../android)

android/external/expat/Makefile: android/external/expat/Makefile.in
ifeq ($(PLATFORM), windows)
	(cd android/external/expat && dos2unix expat_config.h.in)
endif
	(cd android/external/expat && ./configure --enable-static)

expat: android/external/expat/Makefile
	(cd android/external/expat; make)

android/external/fdlibm/Makefile: android/external/fdlibm/makefile.in
	( \
	    cd android/external/fdlibm && \
	    (cp -f makefile.in Makefile.in || true) && \
		bash configure; \
	)
	
fdlibm: android/external/fdlibm/Makefile
	(cd android/external/fdlibm; make)

android/external/icu4c/Makefile: android/external/icu4c/Makefile.in
ifeq ($(PLATFORM), osx)
	(cd android/external/icu4c; patch -p1 -N < ../../../patch/icu4c_common_umutex.h.osx.patch;)
else ifeq ($(PLATFORM), windows)
	(cd android/external/icu4c; dos2unix Makefile.in;)
endif
	(cd android/external/icu4c; ./configure --enable-static;)

icu4c: android/external/icu4c/Makefile
	(cd android/external/icu4c; make)

android/openssl-upstream/Makefile: android/openssl-upstream/Makefile.org
	(cd android/openssl-upstream && \
	    (for x in \
	        progs \
	        handshake_cutthrough \
	        jsse \
	        channelid \
	        eng_dyn_dirs \
	        fix_clang_build \
	        tls12_digests \
	        alpn; \
	        do patch -p1 -N < ../external/openssl/patches/$$x.patch; \
	    done) \
	)
ifeq ($(PLATFORM), windows)
	(cd android/openssl-upstream && dos2unix Makefile.org;)
endif
	(cd android/openssl-upstream && $(OPENSSL_CONFIG);)

openssl: android/openssl-upstream/Makefile
	(cd android/openssl-upstream && make)

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

git-clean:
	git submodule foreach git reset --hard HEAD
	git submodule foreach git clean -f -d -x