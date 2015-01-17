UNAME := $(shell uname)

ifndef CLASSPATH
  CLASSPATH := android
endif

ifndef ARCH
  ARCH := $(shell uname -m)
endif

ifeq ($(UNAME), Darwin)							# OS X
  JAVA_HOME=$(shell /usr/libexec/java_home)
  OPENSSL_CONFIG=./Configure darwin64-x86_64-cc
  CFLAGS=
  CXXFLAGS=
  CC="gcc -fPIC"
else ifeq ($(UNAME), Linux)						# linux on PC
  OPENSSL_CONFIG=./config
  CFLAGS=-fPIC
  CXXFLAGS=-fPIC
  CC="gcc -fPIC"
else ifeq ($(OS) $(ARCH), Windows_NT i686)		# Windows 32
  OPENSSL_CONFIG=./Configure mingw
  CFLAGS=
  CXXFLAGS=
  ARCH=i386
  CC=gcc
else ifeq ($(OS) $(ARCH), Windows_NT x86_64)	# Windows 64
  OPENSSL_CONFIG=./Configure mingw64
  CFLAGS=
  CXXFLAGS=
  CC=gcc
endif


ifeq ($(CLASSPATH), android)

avian: expat fdlibm icu4c openssl
ifeq ($(PLATFORM), windows)
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch || true)
endif
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(ARCH) android=$$(pwd)/../android)

avian-static-lib: expat fdlibm icu4c openssl
ifeq ($(PLATFORM), windows)
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch || true)
endif
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(ARCH) android=$$(pwd)/../android build/$(AVIAN_PLATFORM_TAG)/libavian.a)

avian-classpath: expat fdlibm icu4c openssl
ifeq ($(PLATFORM), windows)
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch || true)
endif
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(ARCH) android=$$(pwd)/../android build/$(AVIAN_PLATFORM_TAG)/classpath.jar)
	
else

avian:
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(ARCH))

avian-static-lib:
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(ARCH) build/$(AVIAN_PLATFORM_TAG)/libavian.a)

avian-classpath:
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(ARCH) build/$(AVIAN_PLATFORM_TAG)/classpath.jar)

endif
	

android/external/expat/Makefile: android/external/expat/Makefile.in
ifeq ($(PLATFORM), windows)
	(cd android/external/expat && dos2unix expat_config.h.in)
endif
	(cd android/external/expat && CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" ./configure --enable-static)

expat: android/external/expat/Makefile
	(cd android/external/expat; make)

android/external/fdlibm/Makefile: android/external/fdlibm/makefile.in
	( \
	    cd android/external/fdlibm && \
	    (cp -f makefile.in Makefile.in || true) && \
		CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" bash configure; \
	)

fdlibm: android/external/fdlibm/Makefile
	(cd android/external/fdlibm; make)

android/external/icu4c/Makefile: android/external/icu4c/Makefile.in
ifeq ($(PLATFORM), darwin)
else ifeq ($(PLATFORM), windows)
	(cd android/external/icu4c; dos2unix Makefile.in;)
endif
	(cd android/external/icu4c; CFLAGS="$(CFLAGS)" CXXFLAGS="$(CXXFLAGS)" ./configure --enable-static;)

icu4c: android/external/icu4c/Makefile
	(cd android/external/icu4c; make)

android/openssl-upstream/Makefile: android/openssl-upstream/Makefile.org
	(cd android/openssl-upstream && \
	    (for x in ../external/openssl/patches/*.patch; \
	        do patch -p1 < $$x; \
	    done) \
	)
   
ifeq ($(PLATFORM), windows)
	(cd android/openssl-upstream && dos2unix Makefile.org;)
endif
	(cd android/openssl-upstream && CC=$(CC) $(OPENSSL_CONFIG);)

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

git-refresh: git-clean
	git submodule update --init --recursive --force

git-clean:
	git submodule foreach git reset --hard HEAD
	git submodule foreach git clean -f -d

.PHONY: avian avian-static-lib avian-classpath git-refresh git-clean expat fdlibm icu4c openssl avian-clean expat-clean fdlibm-clean icu4c-clean openssl-clean git-clean
