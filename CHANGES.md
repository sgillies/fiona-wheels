Changes
=======

## 2023-10-12

Library version changes:

* Update curl to 8.4.0 to address CVE-2023-38545 and CVE-2023-38546 (#112).
* Update vcpkg to commit b40de44891dc1cab11d4722094ae44807a837b98 (#112).

Python version changes:

Python 3.12 has been added.

## 2023-05-16

Library version changes:

* GDAL 3.6.4

## 2023-04-10

Library version changes:

* GEOS 3.11.2

## 2023-01-31

New Platform: macosx-11.0-arm64 wheels are now built on Cirrus Ci
(thanks, folks!).

Configurations changes: GDAL, GEOS, and PROJ builds now use CMake.

## 2022-12-13

Library version changes:

* GDAL 3.5.3
* GEOS 3.11.1

## 2022-10-13

Library version changes:

* GDAL 3.5.2
* PROJ 9.0.1
* GEOS 3.11.0

Python version changes:

Python 3.11 has been added.

Configuration changes:

Extensions are made using Cython >= 0.29.29 to address a problem involving
Python's development mode.

## 2022-06-30

Windows platform wheels are now provided using cibuildwheel and vcpkg.

## 2022-05-20

* Correctly apply patch from GDAL PR #5740 (FlatGeobuf segfault).

## 2022-05-19

Library version changes:

* GDAL 3.5.0
* PROJ 9.0.0

## 2022-02-11

Python version changes:

Python 3.6 has been restored to the build matrix for 1.8.x wheels.

## 2022-02-04

Configuration changes:

* Openssl, curl, and nghttp2 are compiled from source for macos.
* Dropping manylinux1 and switching to manylinux2014 unlocks upgrades of all of
  GDAL's dependencies.
* Multibuild has been updated to commit 3903f7f.

Library version changes:

* GDAL 3.4.1
* Curl 7.80.0
* Nghttp2 1.46.0
* PROJ 8.2.1
* GEOS 3.10.2
* TIFF 4.3.0

Python version changes:

Python 3.6 has been removed and Python 3.10 has been added.

## 2021-05-28

* GEOS 3.9.1
* GDAL 3.3.0
* Patch for GDAL PR #3786

## 2020-06-18

* Disable GEOS support in the GDAL library builds for OS X to prevent conflicts
  with shapely wheels on PyPI (#17).
* Test fiona and shapely wheels together to check for this conflict (#12).
* Ensure that shared libraries in repaired wheels have a "fiona" tag in
  SONAME to prevent conflicts with librairies in rasterio wheels (#13).
* Patch GDAL to fix /vsis3 cache bug.

## 2019-01-27

* Update multibuild commit to 6b0bbd5 for pip 20 support.
* Update GEOS version to 3.8.0.
* Update GDAL version to 2.4.4 and remove patch for 2.4.3.

## 2019-12-07

* Build PROJ with the proj-datumgrid-1.8 package (#33).
* Add 64-bit manylinux1 and macosx Python 3.8 builds.
* Build GEOS for OS X instead of using pre-built versions.

## 2019-12-04

* Update multibuild commit to 4491026 for Python 3.8 support.

## 2019-11-13

* GDAL version 2.4.3 with patch from https://github.com/OSGeo/gdal/pull/2012.
* Cython 0.29.14

## 2019-09-23

* GDAL 2.4.2
* Python 3.4 wheels are removed
* Cython 0.29.5
* Libraries are compiled with -O2 and are stripped.

## 2018-10-31

* Downgrade curl to 7.54, which is more stable in combination with GDAL 2.3.2.

## 2018-10-16

* Patch GDAL 2.3.2 to fully surface AWS error messages.

## 2018-10-11

* Multibuild commit is 548ebc8
* GEOS version 3.6.2
* PROJ 4.9.3 (patched)
* GDAL 2.3.2
* Cython 0.28.3
* Minimum MacOS version is 10.9
* Supports Python 2.7, 3.4, 3.5. 3.6, and 3.7 on 64-bit Linux
* Supports Python 2.7, 3.4, 3.5, 3.6, and 3.7 on OSX (Xcode 9.4)
* Additional, not built-in format drivers: GML and GeoPackage
