# fiona-wheels

Fiona wheel builds on OSX based on https://github.com/sgillies/fiona-wheels

This project builds the fiona binary distributions 
Those distributions, or "wheels", include a GDAL shared library and other
shared libraries supporting many, but not all, of GDAL's format drivers. If you
need the rarely used formats and compressors not found in these wheels, you may
find them in the conda-forge conda channel, or in Docker images published by
the GDAL project.

Wheels 3.7-3.10 are built by GitHub Actions.
