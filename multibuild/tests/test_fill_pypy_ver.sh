# Test Python version fill utility, for pypy
[ "$(fill_pypy_ver 5)" == $LATEST_PP_5 ] || ingest "lpp5"
[ "$(fill_pypy_ver 6)" == $LATEST_PP_6 ] || ingest "lpp6"
[ "$(fill_pypy_ver 7)" == $LATEST_PP_7 ] || ingest "lpp7"
[ "$(fill_pypy_ver 5.0)" == $LATEST_PP_5p0 ] || ingest
[ "$(fill_pypy_ver 5.1)" == $LATEST_PP_5p1 ] || ingest
[ "$(fill_pypy_ver 5.3)" == $LATEST_PP_5p3 ] || ingest
[ "$(fill_pypy_ver 5.4)" == $LATEST_PP_5p4 ] || ingest
[ "$(fill_pypy_ver 5.6)" == $LATEST_PP_5p6 ] || ingest
[ "$(fill_pypy_ver 5.7)" == $LATEST_PP_5p7 ] || ingest
[ "$(fill_pypy_ver 5.8)" == $LATEST_PP_5p8 ] || ingest
[ "$(fill_pypy_ver 5.9)" == $LATEST_PP_5p9 ] || ingest
[ "$(fill_pypy_ver 6.0)" == $LATEST_PP_6p0 ] || ingest
[ "$(fill_pypy_ver 7.0)" == $LATEST_PP_7p0 ] || ingest
[ "$(fill_pypy_ver 7.1)" == $LATEST_PP_7p1 ] || ingest
[ "$(fill_pypy_ver 7.2)" == $LATEST_PP_7p2 ] || ingest
[ "$(fill_pypy_ver 7.3)" == $LATEST_PP_7p3 ] || ingest
