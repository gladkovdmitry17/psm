# Copyright (c) 2006-2010. QLogic Corporation. All rights reserved.
# Copyright (c) 2003-2006, PathScale, Inc. All rights reserved.
#
# This software is available to you under a choice of one of two
# licenses.  You may choose to be licensed under the terms of the GNU
# General Public License (GPL) Version 2, available from the file
# COPYING in the main directory of this source tree, or the
# OpenIB.org BSD license below:
#
#     Redistribution and use in source and binary forms, with or
#     without modification, are permitted provided that the following
#     conditions are met:
#
#      - Redistributions of source code must retain the above
#        copyright notice, this list of conditions and the following
#        disclaimer.
#
#      - Redistributions in binary form must reproduce the above
#        copyright notice, this list of conditions and the following
#        disclaimer in the documentation and/or other materials
#        provided with the distribution.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS
# BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN
# ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
# CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#

SUBDIRS:= ptl_self ptl_ips ptl_am libuuid ipath
export build_dir := .

PSM_VERNO_MAJOR := $(shell sed -n 's/^\#define.*PSM_VERNO_MAJOR.*0x0\?\([1-9a-f]\?[0-9a-f]\+\).*/\1/p' $(build_dir)/psm.h)
PSM_VERNO_MINOR := $(shell sed -n 's/^\#define.*PSM_VERNO_MINOR.*0x\([0-9]\?[0-9a-f]\+\).*/\1/p' $(build_dir)/psm.h)
PSM_LIB_MAJOR   := $(shell printf "%d" ${PSM_VERNO_MAJOR})
PSM_LIB_MINOR   := $(shell printf "%d" `sed -n 's/^\#define.*PSM_VERNO_MINOR.*\(0x[0-9a-f]\+\).*/\1/p' $(build_dir)/psm.h`)

IPATH_LIB_MAJOR := 4
IPATH_LIB_MINOR := 0

export PSM_VERNO_MAJOR
export PSM_LIB_MAJOR
export PSM_VERNO_MINOR
export PSM_LIB_MINOR
export IPATH_LIB_MAJOR
export IPATH_LIB_MINOR
export CCARCH := gcc
export FCARCH := gfortran

top_srcdir := .
include $(top_srcdir)/buildflags.mak
lib_build_dir := $(build_dir)

ifeq (${arch},x86_64)
   INSTALL_LIB_TARG=/usr/lib64
else
   INSTALL_LIB_TARG=/usr/lib
endif

export INSTALL_LIB_TARG

TARGLIB := libpsm_infinipath

MAJOR := $(PSM_LIB_MAJOR)
MINOR := $(PSM_LIB_MINOR)

LDLIBS := -linfinipath -lrt -lpthread -ldl

all: symlinks
	for subdir in $(SUBDIRS); do \
		$(MAKE) -C $$subdir $@ ;\
	done
	$(MAKE) ${TARGLIB}.so

clean:
	for subdir in $(SUBDIRS); do \
		$(MAKE) -C $$subdir $@ ;\
	done
	rm -f *.o ${TARGLIB}.*

distclean: cleanlinks clean

.PHONY: symlinks
symlinks:
	@[[ -L $(build_dir)/include/linux-ppc64 ]] || \
		ln -sf linux-ppc $(build_dir)/include/linux-ppc64
	@[[ -L $(build_dir)/include/linux-x86_64 ]] || \
		ln -sf linux-i386 $(build_dir)/include/linux-x86_64
	@[[ -L $(build_dir)/ipath/ipath_dwordcpy-ppc.c ]] || \
		ln -sf ipath_dwordcpy-ppc64.c $(build_dir)/ipath/ipath_dwordcpy-ppc.c

cleanlinks:
	rm -f $(build_dir)/include/linux-ppc64
	rm -f $(build_dir)/include/linux-x86_64
	rm -f $(build_dir)/ipath/ipath_dwordcpy-ppc.c

install: all
	for subdir in $(SUBDIRS); do \
		$(MAKE) -C $$subdir $@ ;\
	done
	install -t ${INSTALL_LIB_TARG} ${TARGLIB}.so.${MAJOR}.${MINOR}
	(cd ${INSTALL_LIB_TARG} ; \
		ln -sf ${TARGLIB}.so.${MAJOR}.${MINOR} ${TARGLIB}.so.${MAJOR} ; \
		ln -sf ${TARGLIB}.so.${MAJOR} ${TARGLIB}.so)
	install -t /usr/include psm.h psm_mq.h

# rebuild the cscope database, skipping sccs files, done once for
# top level
cscope:
	find * -type f ! -name '[ps].*' \( -iname '*.[cfhs]' -o \
	  -iname \\*.cc -o -name \\*.cpp -o -name \\*.f90 \) -print | cscope -bqu -i -

${TARGLIB}-objs := ptl_am/am_reqrep_shmem.o	\
		   ptl_am/am_reqrep.o		\
		   ptl_am/ptl.o			\
		   ptl_am/kcopyrwu.o		\
		   psm_context.o		\
		   psm_ep.o			\
		   psm_ep_connect.o		\
		   psm_error.o			\
		   psm_utils.o			\
		   psm_timer.o			\
		   psm_am.o			\
		   psm_mq.o			\
		   psm_mq_utils.o		\
		   psm_mq_recv.o		\
		   psm_mpool.o			\
		   psm_stats.o			\
		   psm_memcpy.o			\
		   psm.o			\
		   libuuid/psm_uuid.o		\
		   ptl_ips/ptl.o		\
		   ptl_ips/ptl_rcvthread.o	\
		   ptl_ips/ipserror.o		\
		   ptl_ips/ips_scb.o		\
		   ptl_ips/ips_epstate.o	\
		   ptl_ips/ips_recvq.o		\
		   ptl_ips/ips_recvhdrq.o	\
		   ptl_ips/ips_spio.o		\
		   ptl_ips/ips_proto.o		\
		   ptl_ips/ips_proto_recv.o	\
		   ptl_ips/ips_proto_connect.o  \
		   ptl_ips/ips_proto_expected.o \
		   ptl_ips/ips_tid.o		\
		   ptl_ips/ips_crc32.o 		\
		   ptl_ips/ips_tidflow.o        \
		   ptl_ips/ips_proto_dump.o	\
		   ptl_ips/ips_proto_mq.o       \
		   ptl_ips/ips_proto_am.o       \
		   ptl_ips/ips_subcontext.o	\
		   ptl_ips/ips_path_rec.o       \
		   ptl_ips/ips_opp_path_rec.o   \
		   ptl_ips/ips_writehdrq.o	\
		   ptl_self/ptl.o		\
		   psm_diags.o

${TARGLIB}.so: ${lib_build_dir}/${TARGLIB}.so.${MAJOR}
	ln -fs ${TARGLIB}.so.${MAJOR}.${MINOR} $@

${TARGLIB}.so.${MAJOR}: ${lib_build_dir}/${TARGLIB}.so.${MAJOR}.${MINOR}
	ln -fs ${TARGLIB}.so.${MAJOR}.${MINOR} $@

# when we build the shared library, generate a revision and date
# string in it, for easier id'ing when people may have copied the
# file around.  Generate it such that the ident command can find it
# and strings -a | grep InfiniPath does a reasonable job as well.
${TARGLIB}.so.${MAJOR}.${MINOR}: ${${TARGLIB}-objs}
	date +'char psmi_infinipath_revision[] ="$$""Date: %F %R ${rpm_extra_description}InfiniPath $$";' > ${lib_build_dir}/_revision.c
	$(CC) -c $(BASECFLAGS) $(INCLUDES) _revision.c -o _revision.o
	$(CC) $(LDFLAGS) -o $@ -Wl,-soname=${TARGLIB}.so.${MAJOR} -shared -Wl,--unique='*fastpath*' \
		${${TARGLIB}-objs} _revision.o -Lipath $(LDLIBS)
	@leaks=`nm $@ | grep ' [DT] ' | \
	 grep -v -e ' [DT] \(_fini\|_init\|infinipath_\|ips_\|psmi\|__psmi\?_\|_\rest.pr\|_save.pr\|kcopy\)'`; \
	 if test -n "$$leaks"; then echo "Build failed, leaking symbols:"; echo "$$leaks"; exit 1; fi

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.PHONY: $(SUBDIRS)
