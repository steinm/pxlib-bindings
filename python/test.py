#! /usr/bin/python
# -*- mode: python; coding: utf-8 -*-
# :Project:  pxpy -- silly tester
# :Source:   $Source$
# :Created:  Thu, May 13 2004 01:48:30 CEST
# :Author:   Lele Gaifax <lele@nautilus.homeip.net>
# :Revision: $Revision$ by $Author$
# :Date:     $Date$
# 

import pxpy

t = pxpy.Table("test/Automezzi.DB")
print t
t.open()
t.setPrimaryIndex("test/Automezzi.PX")
t.setBlobFile("test/Automezzi.MB")

print "Fields: ", t.getFieldsCount()

record = t.record

while t.readRecord():
    for i in range(record.getFieldsCount()):
        f = record.fields[i]
        value = f.getValue()
        print "%s: %s" % (f.fname, value)
    print "================================="
    
