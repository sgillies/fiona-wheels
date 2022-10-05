
if [[ "$TRAVIS_OS_NAME" == "osx" ]]; then
  # webp, zstd, xz, libtiff cause a conflict with building webp and libtiff
  # curl from brew requires zstd, use system curl
  # if php is installed, brew tries to reinstall these after installing openblas
  brew remove --ignore-dependencies webp zstd xz libtiff curl php
fi

echo "::group::Build wheel"
  PATH=/opt/homebrew/opt/python@${MB_PYTHON_VERSION}/libexec/bin:$PATH
  python -c "import sys; print(sys.version)" | awk -F \. {'print $1$2'}
  source multibuild/common_utils.sh
  source multibuild/travis_steps.sh
  clean_code $REPO_DIR $BUILD_COMMIT
  build_wheel $REPO_DIR $PLAT
  ls -l "${GITHUB_WORKSPACE}/${WHEEL_SDIR}/"
echo "::endgroup::"

echo "::group::Test wheel"
  PATH=/opt/homebrew/opt/python@${MB_PYTHON_VERSION}/libexec/bin:$PATH
  source multibuild/common_utils.sh
  echo $PIP_CMD
  echo $PYTHON_EXE
  install_run $PLAT
echo "::endgroup::"

