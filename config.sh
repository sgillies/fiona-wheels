# Custom utilities for Rasterio wheels.
#
# Test for OSX with [ -n "$IS_OSX" ].


function build_geos {
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    build_simple geos $GEOS_VERSION https://download.osgeo.org/geos tar.bz2
}


function build_jsonc {
    build_simple json-c $JSONC_VERSION https://s3.amazonaws.com/json-c_releases/releases tar.gz
}


function build_proj {
    if [ -e proj-stamp ]; then return; fi
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    fetch_unpack http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
    (cd proj-${PROJ_VERSION} \
        && patch -u -p1 < ../patches/bd6cf7d527ec88fdd6cc3f078387683d683d0445.diff \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    touch proj-stamp
}


function build_sqlite {
    if [ -e sqlite-stamp ]; then return; fi
    if [ -n "$IS_OSX" ]; then
        :
    else
        fetch_unpack https://www.sqlite.org/2018/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
        (cd sqlite-autoconf-${SQLITE_VERSION} \
            && ./configure --prefix=$BUILD_PREFIX \
            && make -j4 \
            && make install)
    fi
    touch sqlite-stamp
}


function build_expat {
    if [ -e expat-stamp ]; then return; fi
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    if [ -n "$IS_OSX" ]; then
        :
    else
        fetch_unpack https://github.com/libexpat/libexpat/releases/download/R_2_2_6/expat-${EXPAT_VERSION}.tar.bz2
        (cd expat-${EXPAT_VERSION} \
            && ./configure --prefix=$BUILD_PREFIX \
            && make -j4 \
            && make install)
    fi
    touch expat-stamp
}


function build_nghttp2 {
    if [ -e nghttp2-stamp ]; then return; fi
    fetch_unpack https://github.com/nghttp2/nghttp2/releases/download/v${NGHTTP2_VERSION}/nghttp2-${NGHTTP2_VERSION}.tar.gz
    (cd nghttp2-${NGHTTP2_VERSION}  \
        && ./configure --enable-lib-only --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    touch nghttp2-stamp
}


function build_curl {
    if [ -e curl-stamp ]; then return; fi
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    build_nghttp2
    local flags="--prefix=$BUILD_PREFIX --with-nghttp2=$BUILD_PREFIX"
    if [ -n "$IS_OSX" ]; then
        return
        # flags="$flags --with-darwinssl"
    else  # manylinux
        flags="$flags --with-ssl"
        build_openssl
    fi
#    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    (cd curl-${CURL_VERSION} \
        && if [ -z "$IS_OSX" ]; then \
        LIBS=-ldl ./configure $flags; else \
        ./configure $flags; fi\
        && make -j4 \
        && make install)
    touch curl-stamp
}


function build_bundled_deps {
    if [ -n "$IS_OSX" ]; then
        curl -fsSL -o /tmp/deps.zip https://github.com/sgillies/rasterio-wheels/files/2350174/gdal-deps.zip
        (cd / && sudo unzip -o /tmp/deps.zip)
        /gdal/bin/nc-config --libs
        touch geos-stamp && touch hdf5-stamp && touch netcdf-stamp
    else
        suppress build_geos
    fi
}


function build_gdal {
    if [ -e gdal-stamp ]; then return; fi
    build_jpeg
    build_libpng
    build_jsonc
    build_proj
    build_sqlite
    build_curl
    build_expat
    build_bundled_deps

    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"

    if [ -n "$IS_OSX" ]; then
        EXPAT_PREFIX=/usr
        DEPS_PREFIX=/gdal
    else
        EXPAT_PREFIX=$BUILD_PREFIX
        DEPS_PREFIX=$BUILD_PREFIX
    fi

    fetch_unpack http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
    (cd gdal-${GDAL_VERSION} \
        && ./configure \
            --disable-debug \
            --disable-static \
            --prefix=$BUILD_PREFIX \
            --with-crypto=yes \
            --with-curl=curl-config \
            --with-expat=${EXPAT_PREFIX} \
            --with-geos=${DEPS_PREFIX}/bin/geos-config \
            --with-geotiff=internal \
            --with-gif \
            --with-grib \
            --with-hide-internal-symbols \
            --with-jpeg \
            --with-libiconv-prefix=/usr \
            --with-libjson-c=${BUILD_PREFIX} \
            --with-libtiff=internal \
            --with-libz=/usr \
            --with-netcdf=${DEPS_PREFIX} \
            --with-openjpeg=${BUILD_PREFIX} \
            --with-pam \
            --with-png \
            --with-proj=${BUILD_PREFIX} \
            --with-sqlite3=${SQLITE_PREFIX} \
            --with-threads \
            --without-bsb \
            --without-cfitsio \
            --without-dwgdirect \
            --without-ecw \
            --without-fme \
            --without-freexl \
            --without-gnm \
            --without-grass \
            --without-hdf4 \
            --without-hdf5 \
            --without-ingres \
            --without-jasper \
            --without-jp2mrsid \
            --without-jpeg12 \
            --without-kakadu \
            --without-libgrass \
            --without-libkml \
            --without-mrf \
            --without-mrsid \
            --without-mysql \
            --without-netcdf \
            --without-odbc \
            --without-ogdi \
            --without-openjpeg \
            --without-pcidsk \
            --without-pcraster \
            --without-perl \
            --without-pg \
            --without-php \
            --without-python \
            --without-qhull \
            --without-sde \
            --without-sfcgal \
            --without-xerces \
            --without-xml2 \
        && make -j4 \
        && make install)
        if [ -n "$IS_OSX" ]; then
            :
        else
            strip -v --strip-unneeded ${BUILD_PREFIX}/lib/libgdal.so.*
        fi
    touch gdal-stamp
}


function pre_build {
    # Any stuff that you need to do before you start building the wheels
    # Runs in the root directory of this repository.
    #if [ -n "$IS_OSX" ]; then
    #    # Update to latest zlib for OSX build
    #    build_new_zlib
    #fi

    suppress build_nghttp2
    if [ -n "$IS_OSX" ]; then
	:
    else  # manylinux
        suppress build_openssl
    fi

    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz

    # Remove previously installed curl.
    rm -rf /usr/local/lib/libcurl*

    suppress build_curl

    suppress build_jpeg
    suppress build_jsonc
    suppress build_proj
    suppress build_sqlite
    suppress build_expat

    suppress build_bundled_deps

    suppress build_gdal
}


function run_tests {
    unset GDAL_DATA
    unset PROJ_LIB
    if [ -n "$IS_OSX" ]; then
        export PATH=$PATH:${BUILD_PREFIX}/bin
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
    else
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
        export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
        sudo apt-get update
        sudo apt-get install -y ca-certificates
    fi
    cd ../Fiona
    mkdir -p /tmp/Fiona
    cp -R tests /tmp/Fiona
    cd /tmp/Fiona
    python -m pytest -vv tests
    fio --version
    fio env --formats
}


function build_wheel_cmd {
    # Builds wheel with named command, puts into $WHEEL_SDIR
    #
    # Parameters:
    #     cmd  (optional, default "pip_wheel_cmd"
    #        Name of command for building wheel
    #     repo_dir  (optional, default $REPO_DIR)
    #
    # Depends on
    #     REPO_DIR  (or via input argument)
    #     WHEEL_SDIR  (optional, default "wheelhouse")
    #     BUILD_DEPENDS (optional, default "")
    #     MANYLINUX_URL (optional, default "") (via pip_opts function)
    local cmd=${1:-pip_wheel_cmd}
    local repo_dir=${2:-$REPO_DIR}
    [ -z "$repo_dir" ] && echo "repo_dir not defined" && exit 1
    local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
    start_spinner
    if [ -n "$(is_function "pre_build")" ]; then pre_build; fi
    stop_spinner
    if [ -n "$BUILD_DEPENDS" ]; then
        pip install $(pip_opts) $BUILD_DEPENDS
    fi
    (cd $repo_dir && $cmd $wheelhouse)
    repair_wheelhouse $wheelhouse
}
