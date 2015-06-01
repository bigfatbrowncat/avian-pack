UNAME := $(shell uname)

PACKAGE_NAME = avian-pack-$(AVIAN_PLATFORM_TAG)-`git describe`

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
  # In Avian Darwin is now macosx or ios. We use macosx
  AVIAN_PLATFORM_TAG_PART=macosx-x86_64
  EXE_SUFFIX=
  SHARED_LIB_SUFFIX=.dylib
  SHARED_LIB_PREFIX=lib
else ifeq ($(UNAME), Linux)						# linux on PC
  JAVA_HOME=$(shell readlink -f `which javac` | sed "s:bin/javac::")
  OPENSSL_CONFIG=./config
  CFLAGS=-fPIC
  CXXFLAGS=-fPIC
  CC="gcc -fPIC"
  ifeq ($(ARCH), x86_64)
    AVIAN_PLATFORM_TAG_PART=linux-x86_64
  else ifeq ($(ARCH), armv6l)
    AVIAN_PLATFORM_TAG_PART=linux-arm
  else ifeq ($(ARCH), armv7l)
    AVIAN_PLATFORM_TAG_PART=linux-arm
  else
    AVIAN_PLATFORM_TAG_PART=linux-unknown
  endif
  EXE_SUFFIX=
  SHARED_LIB_SUFFIX=.so
  SHARED_LIB_PREFIX=lib
else ifeq ($(OS) $(ARCH), Windows_NT i686)		# Windows 32
  OPENSSL_CONFIG=./Configure mingw
  CFLAGS=
  CXXFLAGS=
  ARCH=i386
  CC=gcc
  AVIAN_PLATFORM_TAG_PART=windows-i386
  EXE_SUFFIX=.exe
  SHARED_LIB_SUFFIX=.dll
  SHARED_LIB_PREFIX=
else ifeq ($(OS) $(ARCH), Windows_NT x86_64)	# Windows 64
  OPENSSL_CONFIG=./Configure mingw64
  CFLAGS=
  CXXFLAGS=
  CC=gcc
  AVIAN_PLATFORM_TAG_PART=windows-x86_64
  EXE_SUFFIX=.exe
  SHARED_LIB_SUFFIX=.dll
  SHARED_LIB_PREFIX=
endif

AVIAN_ARCH := $(ARCH)
ifeq ($(AVIAN_ARCH), armv6l)   # Raspberry Pi
  AVIAN_ARCH := arm
else ifeq ($(AVIAN_ARCH), armv7l)    # Modern ARM (i.e. Cubieboard 4)
  AVIAN_ARCH := arm
endif

ifeq ($(CLASSPATH), android)
  AVIAN_PLATFORM_SUFFIX := -android
else
  AVIAN_PLATFORM_SUFFIX :=
endif

AVIAN_PLATFORM_TAG := $(AVIAN_PLATFORM_TAG_PART)$(AVIAN_PLATFORM_SUFFIX)


ifeq ($(CLASSPATH), android)

avian: expat fdlibm icu4c openssl
ifeq ($(OS), Windows_NT)
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch || true)
endif
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(AVIAN_ARCH) android=$$(pwd)/../android)

avian-static-lib: expat fdlibm icu4c openssl
ifeq ($(OS), Windows_NT)
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch || true)
endif
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(AVIAN_ARCH) android=$$(pwd)/../android build/$(AVIAN_PLATFORM_TAG)/libavian.a)

avian-classpath: expat fdlibm icu4c openssl
ifeq ($(OS), Windows_NT)
	(cd android/external/zlib && cp -f ../../../patch/zlib/* .)
	(cd android/libnativehelper && patch -p1 -N < ../../patch/libnativehelper_jni.h.win32.patch || true)
endif
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(AVIAN_ARCH) android=$$(pwd)/../android build/$(AVIAN_PLATFORM_TAG)/classpath.jar)
	
else

avian:
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(AVIAN_ARCH))

avian-static-lib:
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(AVIAN_ARCH) build/$(AVIAN_PLATFORM_TAG)/libavian.a)

avian-classpath:
	(cd avian && JAVA_HOME="$(JAVA_HOME)" make arch=$(AVIAN_ARCH) build/$(AVIAN_PLATFORM_TAG)/classpath.jar)

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

package: avian
	@echo Packaging avian-pack...
	mkdir -p $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
	cp -f avian/build/$(AVIAN_PLATFORM_TAG)/avian$(EXE_SUFFIX) $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
	cp -f avian/build/$(AVIAN_PLATFORM_TAG)/avian-dynamic$(EXE_SUFFIX) $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
	cp -rf avian/build/$(AVIAN_PLATFORM_TAG)/binaryToObject $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
	cp -f avian/build/$(AVIAN_PLATFORM_TAG)/classpath.jar $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
	cp -f avian/build/$(AVIAN_PLATFORM_TAG)/generator$(EXE_SUFFIX) $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
	cp -f avian/build/$(AVIAN_PLATFORM_TAG)/libavian.a $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
	cp -f avian/build/$(AVIAN_PLATFORM_TAG)/$(SHARED_LIB_PREFIX)jvm$(SHARED_LIB_SUFFIX) $(PACKAGE_NAME)/avian/build/$(AVIAN_PLATFORM_TAG)/
ifeq ($(CLASSPATH), android)
ifeq ($(OS), Windows_NT)	# Windows
		mkdir -p $(PACKAGE_NAME)/android/external/icu4c/lib/
		cp -f android/external/icu4c/lib/libsicuin.a $(PACKAGE_NAME)/android/external/icu4c/lib/
		cp -f android/external/icu4c/lib/libsicuuc.a $(PACKAGE_NAME)/android/external/icu4c/lib/
		cp -f android/external/icu4c/lib/sicudt.a $(PACKAGE_NAME)/android/external/icu4c/lib/
else
		mkdir -p $(PACKAGE_NAME)/android/external/icu4c/lib/
		cp -f android/external/icu4c/lib/libicui18n.a $(PACKAGE_NAME)/android/external/icu4c/lib/
		cp -f android/external/icu4c/lib/libicuuc.a $(PACKAGE_NAME)/android/external/icu4c/lib/
		cp -f android/external/icu4c/lib/libicudata.a $(PACKAGE_NAME)/android/external/icu4c/lib/
endif
	
	mkdir -p $(PACKAGE_NAME)/android/external/fdlibm/
	cp -f android/external/fdlibm/libfdm.a $(PACKAGE_NAME)/android/external/fdlibm/
	
	mkdir -p $(PACKAGE_NAME)/android/external/expat/.libs/
	cp -f android/external/expat/.libs/libexpat.a $(PACKAGE_NAME)/android/external/expat/.libs/
	
	mkdir -p $(PACKAGE_NAME)/android/openssl-upstream/
	cp -f android/openssl-upstream/libssl.a $(PACKAGE_NAME)/android/openssl-upstream/
	cp -f android/openssl-upstream/libcrypto.a $(PACKAGE_NAME)/android/openssl-upstream/
endif

ifeq ($(OS), Windows_NT)	# Windows
	@echo Archiving the package $(PACKAGE_NAME).zip...
	( \
	    cd $(PACKAGE_NAME); \
	    zip -r ../$(PACKAGE_NAME).zip *;\
	)
else
	@echo Archiving the package $(PACKAGE_NAME).tar.bz2...
	( \
	    cd $(PACKAGE_NAME); \
	    tar -cjf ../$(PACKAGE_NAME).tar.bz2 *;\
	)
endif
	rm -rf $(PACKAGE_NAME)


.PHONY: avian avian-static-lib avian-classpath git-refresh git-clean expat fdlibm icu4c openssl avian-clean expat-clean fdlibm-clean icu4c-clean openssl-clean git-clean package
