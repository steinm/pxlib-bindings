#  -*- Pyrex -*-
# :Project:  pxpy -- Python wrapper around pxlib
# :Source:   $Source$
# :Created:  Sun, Apr 04 2004 00:20:28 CEST
# :Author:   Lele Gaifax <lele@nautilus.homeip.net>
# :Revision: $Revision$ by $Author, $Date$
# 

import datetime

cdef extern from "Python.h": 
    object PyString_FromStringAndSize(char *s, int len)

cdef extern from "paradox.h":
    ctypedef enum fieldtype_t:
        pxfAlpha = 0x01
        pxfDate = 0x02
        pxfShort = 0x03
        pxfLong = 0x04
        pxfCurrency = 0x05
        pxfNumber = 0x06
        pxfLogical = 0x09
        pxfMemoBLOb = 0x0C
        pxfBLOb = 0x0D
        pxfFmtMemoBLOb = 0x0E
        pxfOLE = 0x0F
        pxfGraphic = 0x10
        pxfTime = 0x14
        pxfTimestamp = 0x15
        pxfAutoInc = 0x16
        pxfBCD = 0x17
        pxfBytes = 0x18
        pxfNumTypes = 0x18
        
    ctypedef struct pxfield_t:
        char *px_fname
        char px_ftype
        int px_flen
        int px_fdc
        
    ctypedef struct pxhead_t:
        char *px_tablename
        int px_recordsize
        char px_filetype
        int px_fileversion
        int px_numrecords
        int px_theonumrecords
        int px_numfields
        int px_maxtablesize
        int px_headersize
        int px_fileblocks
        int px_firstblock
        int px_lastblock
        int px_indexfieldnumber
        int px_indexroot
        int px_numindexlevels
        int px_writeprotected
        int px_doscodepage
        int px_primarykeyfields
        char px_modifiedflags1
        char px_modifiedflags2
        char px_sortorder
        int px_autoinc
        int px_fileupdatetime
        char px_refintegrity
        pxfield_t *px_fields

    ctypedef struct pxdoc_t:
        char *px_name
        pxhead_t *px_head
        void *(*malloc)(pxdoc_t *p, unsigned int size, char *caller)
        void  (*free)(pxdoc_t *p, void *mem)
        
    ctypedef struct pxdatablockinfo_t
    ctypedef struct pxblob_t:
        char *px_name
        pxdoc_t * pxdoc
        
    ctypedef struct pxpindex_t
    ctypedef struct pxstream_t

    pxdoc_t *PX_new()
    int PX_open_file(pxdoc_t *pxdoc, char *filename)
    int PX_read_primary_index(pxdoc_t *pindex)
    int PX_add_primary_index(pxdoc_t *pxdoc, pxdoc_t *pindex)
    int PX_setargetencoding(pxdoc_t *pxdoc, char *encoding)
    int PX_set_inputencoding(pxdoc_t *pxdoc, char *encoding)
    pxblob_t *PX_new_blob(pxdoc_t *pxdoc)
    int PX_open_blob_file(pxblob_t *pxdoc, char *filename)
    int PX_close(pxdoc_t *pxdoc)
    int PX_close_blob(pxblob_t *pxdoc)
    void *PX_get_record(pxdoc_t *pxdoc, int recno, void *data)
    void *PX_get_record2(pxdoc_t *pxdoc, int recno, void *data, int *deleted, pxdatablockinfo_t *pxdbinfo)
    int PX_get_data_alpha(pxdoc_t *pxdoc, void *data, int len, char **value)
    int PX_get_data_bytes(pxdoc_t *pxdoc, void *data, int len, char **value)
    int PX_get_data_double(pxdoc_t *pxdoc, void *data, int len, double *value)
    int PX_get_data_long(pxdoc_t *pxdoc, void *data, int len, long *value)
    int PX_get_data_short(pxdoc_t *pxdoc, void *data, int len, short int *value)
    int PX_get_data_byte(pxdoc_t *pxdoc, void *data, int len, char *value)
    char *PX_read_blobdata(pxblob_t *pxblob, void *data, int len, int *mod, int *blobsize)
    void PX_SdnToGregorian(long int sdn, int *pYear, int *pMonth, int *pDay)
    long int PX_GregorianToSdn(int year, int month, int day)


cdef class PXDoc:
    cdef pxdoc_t *doc
    cdef char *filename
    
    def __new__(self, filename):
        self.filename = filename
        self.doc = PX_new()

    def open(self):
        if PX_open_file(self.doc, self.filename)<0:
            raise "Couldn't open `%s`" % self.filename
    
    def __dealloc__(self):
        PX_close(self.doc)


cdef class BlobFile:
    cdef pxblob_t *blob
    cdef char *filename

    def __new__(self, PXDoc table, filename):
        self.filename = filename
        self.blob = PX_new_blob(table.doc)
        
    def open(self):
        if PX_open_blob_file(self.blob, self.filename)<0:
            raise "Couldn't open blob `%s`" % self.filename
        

cdef class PrimaryIndex(PXDoc):
    def open(self):
        PXDoc.open(self)
        if PX_read_primary_index(self.doc)<0:
            raise "Couldn't read primary index `%s`" % self.filename


cdef class Record


cdef class Table(PXDoc):
    cdef readonly Record record
    cdef int current_recno
    cdef BlobFile blob
    
    def open(self):
        PXDoc.open(self)
        self.record = Record(self)
        self.current_recno = 0
        
    def setPrimaryIndex(self, indexname):
        cdef PrimaryIndex index
        
        index = PrimaryIndex(indexname)
        index.open()
        if PX_add_primary_index(self.doc, index.doc)<0:
            raise "Couldn't add primary index `%s`" % index.filename

    def setBlobFile(self, blobfilename):
        self.blob = BlobFile(self, blobfilename)
        self.blob.open()
    
    def getFieldsCount(self):
        return self.record.getFieldsCount()
    
    def readRecord(self, recno=None):
        if not recno:
            recno = self.current_recno+1
        else:
            self.current_recno = recno

        if recno>=self.doc.px_head.px_numrecords:
            return False

        self.current_recno = recno
        
        return self.record.read(recno)

cdef class Field:
    cdef void *data
    cdef Record record
    cdef readonly fname
    cdef ftype
    cdef flen
    
    def __new__(self, Record record, int index, int offset):
        self.record = record
        self.fname = record.table.doc.px_head.px_fields[index].px_fname
        self.ftype = record.table.doc.px_head.px_fields[index].px_ftype
        self.data = record.data+offset
        self.flen = record.table.doc.px_head.px_fields[index].px_flen
        
    def getValue(self):
        cdef char *value_alpha
        cdef double value_double
        cdef long value_long
        cdef char value_char
        cdef short value_short
        cdef int year, month, day
        cdef char *blobdata
        cdef int size
        cdef int mod_nr

        if self.ftype == pxfAlpha:
            if PX_get_data_alpha(self.record.table.doc,
                                 self.data, self.flen, &value_alpha)<0:
                raise "Cannot extract alpha field '%s'" % self.fname

            if value_alpha:
                value = value_alpha
                self.record.table.doc.free(self.record.table.doc,
                                             value_alpha)
                return value
            else:
                return None
        
        elif self.ftype == pxfDate:
            if PX_get_data_long(self.record.table.doc,
                                self.data, self.flen, &value_long)<0:
                raise "Cannot extract long field '%s'" % self.fname
            if value_long:
                PX_SdnToGregorian(value_long+1721425,
                                  &year, &month, &day)
                return datetime.date(year, month, day)
            else:
                return None
            
        elif self.ftype == pxfShort:
            if PX_get_data_short(self.record.table.doc,
                                self.data, self.flen, &value_short)<0:
                raise "Cannot extract short field '%s'" % self.fname
            
            return value_short
        
        elif self.ftype == pxfLong or self.ftype == pxfAutoInc:
            if PX_get_data_long(self.record.table.doc,
                                self.data, self.flen, &value_long)<0:
                raise "Cannot extract long field '%s'" % self.fname
            
            return value_long

        elif self.ftype == pxfCurrency or self.ftype == pxfNumber:
            if PX_get_data_double(self.record.table.doc,
                                  self.data, self.flen, &value_double)<0:
                raise "Cannot extract double field '%s'" % self.fname
            
            return value_double

        elif self.ftype == pxfLogical:
            if PX_get_data_byte(self.record.table.doc,
                                self.data, self.flen, &value_char)<0:
                raise "Cannot extract double field '%s'" % self.fname
            if value_char:
                return True
            else:
                return False

        elif self.ftype in [pxfMemoBLOb, pxfBLOb, pxfFmtMemoBLOb, pxfGraphic]:
            if not self.record.table.blob:
                return "NO BLOB FILE"

            blobdata = PX_read_blobdata(self.record.table.blob.blob,
                                        self.data, self.flen,
                                        &mod_nr, &size)
            if blobdata and size>0:
                return PyString_FromStringAndSize(blobdata, size)
            
        elif self.ftype == pxfOLE:
            pass
        elif self.ftype == pxfTime:
            if PX_get_data_long(self.record.table.doc,
                                self.data, self.flen, &value_long)<0:
                raise "Cannot extract long field '%s'" % self.fname
            if value_long:
                return datetime.time(value/3600000,
                                     value/60000%60,
                                     value%60000/1000.0)
            else:
                return None
            
        elif self.ftype == pxfTimestamp:
            pass
        elif self.ftype == pxfBCD:
            pass
        elif self.ftype == pxfBytes:
            pass
        elif self.ftype == pxfNumTypes:
            pass


cdef class Record:
    cdef void *data
    cdef Table table
    cdef public fields
    
    def __new__(self, Table table):
        cdef int offset
        
        self.data = table.doc.malloc(table.doc,
                                       table.doc.px_head.px_recordsize,
                                       "Memory for record")
        self.table = table
        self.fields = []
        offset = 0
        for i in range(self.getFieldsCount()):
            field = Field(self, i, offset)
            self.fields.append(field)
            offset = offset + table.doc.px_head.px_fields[i].px_flen

    def getFieldsCount(self):
        return self.table.doc.px_head.px_numfields
    
    def read(self, recno):
        if PX_get_record(self.table.doc, recno, self.data) == NULL:
            raise "Couldn't get record %d from '%s'" % (recno,
                                                        self.table.filename)
        return True
    
