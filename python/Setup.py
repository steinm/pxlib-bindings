#  -*- Python -*- -*- coding: iso-8859-1 -*-
# :Project:  pxpy -- Module setup
# :Source:   $Source$
# :Created:  Sun, Apr 04 2004 00:14:12 CEST
# :Author:   Lele Gaifax <lele@nautilus.homeip.net>
# :Revision: $Revision$ by $Author$
# :Date:     $Date$
# 

from distutils.core import setup
from distutils.extension import Extension
from Pyrex.Distutils import build_ext

setup(
  name = 'python-pxlib',
  description = "Python wrapper around pxlib",
  version = '0.0.1',
  author = "Lele Gaifax",
  author_email = "lele@nautilus.homeip.net",
  url = "http://pxlib.sourceforge.net/",
  
  ext_modules=[ 
    Extension("pxpy", ["pxpy.pyx"],
              # Uncomment, to use current version
              #include_dirs=["../../pxlib/include/"],
              #library_dirs=["../../pxlib/src/.libs"],
              libraries=["px"]),
    ],
  cmdclass = {'build_ext': build_ext}
)
