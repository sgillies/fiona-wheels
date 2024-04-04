# Custom utilities for Fiona wheels.
#
# Test for OSX with [ -n "$IS_OSX" ].

function fetch_unpack {
    # Fetch input archive name from input URL
    # Parameters
    #    url - URL from which to fetch archive
    #    archive_fname (optional) archive name
    #
    # Echos unpacked directory and file names.
    #
    # If `archive_fname` not specified then use basename from `url`
    # If `archive_fname` already present at download location, use that instead.
    local url=$1
    if [ -z "$url" ];then echo "url not defined"; exit 1; fi
    local archive_fname=${2:-$(basename $url)}
    local arch_sdir="${ARCHIVE_SDIR:-archives}"
    # Make the archive directory in case it doesn't exist
    mkdir -p $arch_sdir
    local out_archive="${arch_sdir}/${archive_fname}"
    # If the archive is not already in the archives directory, get it.
    if [ ! -f "$out_archive" ]; then
        # Source it from multibuild archives if available.
        local our_archive="${MULTIBUILD_DIR}/archives/${archive_fname}"
        if [ -f "$our_archive" ]; then
            ln -s $our_archive $out_archive
        else
            # Otherwise download it.
            curl --insecure -L $url > $out_archive
        fi
    fi
    # Unpack archive, refreshing contents, echoing dir and file
    # names.
    rm_mkdir arch_tmp
    install_rsync
    (cd arch_tmp && \
        untar ../$out_archive && \
        ls -1d * &&
        rsync --delete -ah * ..)
}


function build_geos {
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    if [ -e geos-stamp ]; then return; fi
    local cmake=cmake
    fetch_unpack http://download.osgeo.org/geos/geos-${GEOS_VERSION}.tar.bz2
    (cd geos-${GEOS_VERSION} \
        && mkdir build && cd build \
        && $cmake .. \
        -DCMAKE_INSTALL_PREFIX:PATH=$BUILD_PREFIX \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_IPO=ON \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        && $cmake --build . -j4 \
        && $cmake --install .)
    touch geos-stamp
}


function build_jsonc {
    if [ -e jsonc-stamp ]; then return; fi
    local cmake=cmake
    fetch_unpack https://s3.amazonaws.com/json-c_releases/releases/json-c-${JSONC_VERSION}.tar.gz
    (cd json-c-${JSONC_VERSION} \
        && $cmake -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET . \
        && make -j4 \
        && make install)
    if [ -n "$IS_OSX" ]; then
        for lib in $(ls ${BUILD_PREFIX}/lib/libjson-c.5*.dylib); do
            install_name_tool -id $lib $lib
        done
        for lib in $(ls ${BUILD_PREFIX}/lib/libjson-c.dylib); do
            install_name_tool -id $lib $lib
        done
    fi
    touch jsonc-stamp
}


function build_proj {
    CFLAGS="$CFLAGS -DPROJ_RENAME_SYMBOLS -g -O2"
    CXXFLAGS="$CXXFLAGS -DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -g -O2"
    if [ -e proj-stamp ]; then return; fi
    local cmake=cmake
    build_sqlite
    fetch_unpack http://download.osgeo.org/proj/proj-${PROJ_VERSION}.tar.gz
    (cd proj-${PROJ_VERSION} \
        && mkdir build && cd build \
        && $cmake .. \
        -DCMAKE_INSTALL_PREFIX:PATH=$BUILD_PREFIX \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DENABLE_IPO=ON \
        -DBUILD_APPS:BOOL=OFF \
        -DBUILD_TESTING:BOOL=OFF \
        && $cmake --build . -j4 \
        && $cmake --install .)
    touch proj-stamp
}


function build_tiff {
    if [ -e tiff-stamp ]; then return; fi
    build_zlib
    build_jpeg
    build_xz
    fetch_unpack https://download.osgeo.org/libtiff/tiff-${TIFF_VERSION}.tar.gz
    (cd tiff-${TIFF_VERSION} \
        && mv VERSION VERSION.txt \
        && (patch -u --force < ../patches/libtiff-rename-VERSION.patch || true) \
        && ./configure --prefix=$BUILD_PREFIX \
        && make -j4 \
        && make install)
    touch tiff-stamp
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


function build_openssl {
    if [ -e openssl-stamp ]; then return; fi
    fetch_unpack ${OPENSSL_DOWNLOAD_URL}/${OPENSSL_ROOT}.tar.gz
    check_sha256sum $ARCHIVE_SDIR/${OPENSSL_ROOT}.tar.gz ${OPENSSL_HASH}
    (cd ${OPENSSL_ROOT} \
        && ./config no-ssl2 -fPIC --prefix=$BUILD_PREFIX \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
    touch openssl-stamp
}


function build_curl {
    if [ -e curl-stamp ]; then return; fi
    CFLAGS="$CFLAGS -g -O2"
    CXXFLAGS="$CXXFLAGS -g -O2"
    build_openssl
    build_nghttp2
    local flags="--prefix=$BUILD_PREFIX --with-nghttp2=$BUILD_PREFIX --with-libz --with-ssl"
    #    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz
    (cd curl-${CURL_VERSION} \
        && LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$BUILD_PREFIX/lib:$BUILD_PREFIX/lib64 ./configure $flags \
        && make -j4 \
        && if [ -n "$IS_OSX" ]; then sudo make install; else make install; fi)
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

    CFLAGS="$CFLAGS -DPROJ_RENAME_SYMBOLS -g -O2"
    CXXFLAGS="$CXXFLAGS -DPROJ_RENAME_SYMBOLS -DPROJ_INTERNAL_CPP_NAMESPACE -g -O2"

    if [ -n "$IS_OSX" ]; then
        GEOS_CONFIG="-DGDAL_USE_GEOS=OFF"
    else
        GEOS_CONFIG="-DGDAL_USE_GEOS=ON"
    fi

    local cmake=cmake
    fetch_unpack http://download.osgeo.org/gdal/${GDAL_VERSION}/gdal-${GDAL_VERSION}.tar.gz
    (cd gdal-${GDAL_VERSION} \
        && mkdir build \
        && cd build \
        && $cmake .. \
        -DCMAKE_INSTALL_PREFIX=$BUILD_PREFIX \
        -DCMAKE_INCLUDE_PATH=$BUILD_PREFIX/include \
        -DCMAKE_LIBRARY_PATH=$BUILD_PREFIX/lib \
        -DCMAKE_PROGRAM_PATH=$BUILD_PREFIX/bin \
        -DCMAKE_OSX_DEPLOYMENT_TARGET=$MACOSX_DEPLOYMENT_TARGET \
        -DBUILD_SHARED_LIBS=ON \
        -DCMAKE_BUILD_TYPE=Release \
        -DGDAL_BUILD_OPTIONAL_DRIVERS=OFF \
        -DOGR_BUILD_OPTIONAL_DRIVERS=ON \
        ${GEOS_CONFIG} \
        -DGDAL_USE_TIFF=ON \
        -DGDAL_USE_TIFF_INTERNAL=OFF \
        -DGDAL_USE_GEOTIFF_INTERNAL=ON \
        -DGDAL_ENABLE_DRIVER_GIF=ON \
        -DGDAL_ENABLE_DRIVER_GRIB=ON \
        -DGDAL_ENABLE_DRIVER_JPEG=ON \
        -DGDAL_USE_ICONV=ON \
        -DGDAL_USE_JSONC=ON \
        -DGDAL_USE_JSONC_INTERNAL=OFF \
        -DGDAL_USE_ZLIB=ON \
        -DGDAL_USE_ZLIB_INTERNAL=OFF \
        -DGDAL_ENABLE_DRIVER_PNG=ON \
        -DGDAL_ENABLE_DRIVER_OGCAPI=OFF \
        -DOGR_ENABLE_DRIVER_GPKG=ON \
        -DBUILD_PYTHON_BINDINGS=OFF \
        -DBUILD_JAVA_BINDINGS=OFF \
        -DBUILD_CSHARP_BINDINGS=OFF \
        -DGDAL_USE_SFCGAL=OFF \
        -DGDAL_USE_XERCESC=OFF \
        -DGDAL_USE_LIBXML2=OFF \
        && $cmake --build . -j4 \
        && $cmake --install .)
    if [ -n "$IS_OSX" ]; then
        :
    else
        strip -v --strip-unneeded ${BUILD_PREFIX}/lib/libgdal.so.* || true
        strip -v --strip-unneeded ${BUILD_PREFIX}/lib64/libgdal.so.* || true
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

    local cmake=$(get_modern_cmake)
    suppress build_openssl
    suppress build_nghttp2

    if [ -n "$IS_OSX" ]; then
        rm /usr/local/lib/libpng* || true
    fi


    fetch_unpack https://curl.haxx.se/download/curl-${CURL_VERSION}.tar.gz

    # Remove previously installed curl.
    rm -rf /usr/local/lib/libcurl* || true

    suppress build_curl

    suppress build_jpeg
    suppress build_jsonc
    suppress build_tiff
    suppress build_sqlite
    suppress build_proj
    suppress build_expat
    suppress build_geos

    if [ -n "$IS_OSX" ]; then
        export LDFLAGS="${LDFLAGS} -Wl,-rpath,${BUILD_PREFIX}/lib"
    fi

    suppress build_gdal
}


function run_tests {
    unset GDAL_DATA
    unset PROJ_DATA
    if [ -n "$IS_OSX" ]; then
        export PATH=$PATH:${BUILD_PREFIX}/bin
        export LC_ALL=en_US.UTF-8
        export LANG=en_US.UTF-8
    else
        export LC_ALL=C.UTF-8
        export LANG=C.UTF-8
        export CURL_CA_BUNDLE=/etc/ssl/certs/ca-certificates.crt
        apt-get update
        apt-get install -y ca-certificates
    fi
    cp -R ../Fiona/tests ./tests
    python -m pip install $TEST_DEPENDS
    GDAL_ENABLE_DEPRECATED_DRIVER_GTM=YES python -m pytest -vv tests -k "not test_collection_zip_http and not test_mask_polygon_triangle and not test_show_versions and not test_append_or_driver_error and not [PCIDSK] and not cannot_append[FlatGeobuf]"
    fio --version
    fio env --formats
    python ../test_fiona_issue383.py
}


function build_wheel_cmd {
    local cmd=${1:-build_cmd}
    local repo_dir=${2:-$REPO_DIR}
    [ -z "$repo_dir" ] && echo "repo_dir not defined" && exit 1
    local wheelhouse=$(abspath ${WHEEL_SDIR:-wheelhouse})
    start_spinner
    if [ -n "$(is_function "pre_build")" ]; then pre_build; fi
    stop_spinner
    pip install -U pip
    pip install -U build
    if [ -n "$BUILD_DEPENDS" ]; then
        pip install $(pip_opts) $BUILD_DEPENDS
    fi
    (cd $repo_dir && GDAL_VERSION=3.8.4 $cmd $wheelhouse)
    if [ -n "$IS_OSX" ]; then
        delocate-listdeps --all $wheelhouse/*.whl
    else  # manylinux
        pip install -I "git+https://github.com/sgillies/auditwheel.git#egg=auditwheel"
    fi
    repair_wheelhouse $wheelhouse
}


function build_cmd {
    local abs_wheelhouse=$1
    python -m build -o $abs_wheelhouse
}


function macos_arm64_native_build_setup {
    # Setup native build for single arch arm_64 wheels
    export PLAT="arm64"
    # We don't want universal2 builds and only want an arm64 build
    export _PYTHON_HOST_PLATFORM="macosx-11.0-arm64"
    export ARCHFLAGS+=" -arch arm64"
    $@
}
