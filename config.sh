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
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    if [ -e proj-stamp ]; then return; fi
    fetch_unpack http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
    (cd proj-${PROJ_VERSION} \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    if [ -n "$IS_OSX" ]; then
        :
    else
        strip -v --strip-unneeded ${BUILD_PREFIX}/lib/libproj.so.*
    fi
    touch proj-stamp
}


function build_sqlite {
    if [ -e sqlite-stamp ]; then return; fi
    fetch_unpack https://www.sqlite.org/2020/sqlite-autoconf-${SQLITE_VERSION}.tar.gz
    (cd sqlite-autoconf-${SQLITE_VERSION} \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    touch sqlite-stamp
}


function build_expat {
    if [ -e expat-stamp ]; then return; fi
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


function build_gdal {
    if [ -e gdal-stamp ]; then return; fi

    build_curl
    build_jpeg
    build_libpng
    build_jsonc
    build_tiff
    build_proj
    build_sqlite
    build_expat
    build_geos

    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"

    if [ -n "$IS_OSX" ]; then
        EXPAT_PREFIX=/usr
        GEOS_CONFIG="--without-geos"
    else
        EXPAT_PREFIX=$BUILD_PREFIX
        GEOS_CONFIG="--with-geos=${BUILD_PREFIX}/bin/geos-config"
    fi

    fetch_unpack http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
    (cd gdal-${GDAL_VERSION} \
        && ./configure \
	        --with-crypto=yes \
	        --with-hide-internal-symbols \
            --disable-debug \
            --disable-static \
	        --disable-driver-elastic \
            --prefix=$BUILD_PREFIX \
            --with-curl=curl-config \
            --with-expat=${EXPAT_PREFIX} \
            ${GEOS_CONFIG} \
            --with-geotiff=internal \
            --with-gif \
            --with-jpeg \
            --with-libiconv-prefix=/usr \
            --with-libjson-c=${BUILD_PREFIX} \
            --with-libtiff=internal \
            --with-libz=/usr \
            --with-pam \
            --with-png \
            --with-proj=${BUILD_PREFIX} \
            --with-sqlite3=${BUILD_PREFIX} \
            --with-threads \
            --without-bsb \
            --without-cfitsio \
            --without-dwgdirect \
            --without-ecw \
            --without-fme \
            --without-freexl \
            --without-gnm \
            --without-grass \
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
            --without-odbc \
            --without-ogdi \
            --without-pcidsk \
            --without-pcraster \
            --without-perl \
            --without-pg \
            --without-php \
            --without-python \
            --without-qhull \
            --without-sde \
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
    suppress build_tiff
    suppress build_proj
    suppress build_sqlite
    suppress build_expat
    suppress build_geos

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
    cp -R ../Fiona/tests ./tests
    python -m pytest -vv tests -k "not test_collection_zip_http and not test_mask_polygon_triangle and not test_show_versions"
    fio --version
    fio env --formats
    pip install shapely && python ../test_fiona_issue383.py
}


function build_wheel_cmd {
    # Update the container's auditwheel with our patched version.
    if [ -n "$IS_OSX" ]; then
	:
    else  # manylinux
        /opt/python/cp37-cp37m/bin/pip install -I "git+https://github.com/sgillies/auditwheel.git#egg=auditwheel"
    fi

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
    (cd $repo_dir && PIP_NO_BUILD_ISOLATION=0 PIP_USE_PEP517=0 $cmd $wheelhouse)
    if [ -n "$IS_OSX" ]; then
	:
    else  # manylinux
        /opt/python/cp37-cp37m/bin/pip install -I "git+https://github.com/sgillies/auditwheel.git#egg=auditwheel"
    fi
    repair_wheelhouse $wheelhouse
}
