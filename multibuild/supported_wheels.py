#!/usr/bin/env python
"""  Filter out wheel filenames not supported on this platform
"""
from __future__ import print_function

import sys
from os.path import basename

from packaging.tags import sys_tags

try:
    from wheel.install import WHEEL_INFO_RE as wheel_matcher
except ImportError:  # As of Wheel 0.32.0
    from wheel.wheelfile import WHEEL_INFO_RE
    wheel_matcher = WHEEL_INFO_RE.match


def tags_for(fname):
    # Copied from WheelFile code
    parsed_filename = wheel_matcher(basename(fname))
    tags = parsed_filename.groupdict()
    for pyver in tags['pyver'].split('.'):
        for abi in tags['abi'].split('.'):
            for plat in tags['plat'].split('.'):
                yield (pyver, abi, plat)


def main():
    supported = {(tag.interpreter, tag.abi, tag.platform)
                 for tag in sys_tags()
    }
    for fname in sys.argv[1:]:
        tags = set(tags_for(fname))
        if supported.intersection(tags):
            print(fname)

if __name__ == '__main__':
    main()
