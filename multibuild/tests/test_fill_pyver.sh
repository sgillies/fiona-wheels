# Test python version fill utility
[ "$(fill_pyver 2)" == $LATEST_2p7 ] || ingest
[ "$(fill_pyver 2.7)" == $LATEST_2p7 ] || ingest
[ "$(fill_pyver 2.7.8)" == "2.7.8" ] || ingest
[ "$(fill_pyver 3)" == $LATEST_3p10 ] || ingest
[ "$(fill_pyver 3.10)" == $LATEST_3p10 ] || ingest
[ "$(fill_pyver 3.10.0)" == "3.10.0rc1" ] || ingest
[ "$(fill_pyver 3.9)" == $LATEST_3p9 ] || ingest
[ "$(fill_pyver 3.9.0)" == "3.9.0" ] || ingest
[ "$(fill_pyver 3.8)" == $LATEST_3p8 ] || ingest
[ "$(fill_pyver 3.8.0)" == "3.8.0" ] || ingest
[ "$(fill_pyver 3.7)" == $LATEST_3p7 ] || ingest
[ "$(fill_pyver 3.7.0)" == "3.7.0" ] || ingest
[ "$(fill_pyver 3.6)" == $LATEST_3p6 ] || ingest
[ "$(fill_pyver 3.6.0)" == "3.6.0" ] || ingest
[ "$(fill_pyver 3.5)" == $LATEST_3p5 ] || ingest
[ "$(fill_pyver 3.5.0)" == "3.5.0" ] || ingest
