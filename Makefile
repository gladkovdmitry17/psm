# Copyright (c) 2013 Intel Corporation.  All rights reserved.
# Copyright (c) 2006-2011. QLogic Corporation. All rights reserved.
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

top_srcdir := $(shell pwd)
build_dir ?= $(top_srcdir)
include $(top_srcdir)/buildflags.mak
lib_build_dir := $(build_dir)
ifdef LOCAL_PREFIX
	INSTALL_PREFIX := $(LOCAL_PREFIX)
else
	INSTALL_PREFIX := /usr
endif
libdir ?= $(INSTALL_PREFIX)/lib64
sbindir ?= $(INSTALL_PREFIX)/sbin

INSTALL_LIB_TARG = $(libdir)
INSTALL_SBIN_TARG = $(sbindir)
RPM_BUILD_DIR=${top_srcdir}/rpmbuild
TARG_DIR ?= $(top_srcdir)
TMI_DIR := $(top_srcdir)/contrib/$(TMI_NAME)

TMI_NAME := tmi-2009-11-20
RPM_NAME := $(if $(PSM_HAVE_SCIF:0=),$(if $(MIC:0=),intel-mic-psm-card,intel-mic-psm),infinipath-psm)
TARBALL_NAME := $(if $(PSM_HAVE_SCIF:0=),$(if $(MIC:0=),mic-psm-card,mic-psm),ipath-psm)
TARGLIB := libpsm_infinipath

SUBDIRS:= ptl_self ptl_ips ptl_am libuuid ipath

LDLIBS := -linfinipath $(SCIF_LINK_FLAGS) -lrt -lpthread -ldl ${EXTRA_LIBS}

# Library version information
PSM_VERNO_MAJOR := $(shell sed -n 's/^\#define.*PSM_VERNO_MAJOR.*0x0\?\([1-9a-f]\?[0-9a-f]\+\).*/\1/p' $(build_dir)/psm.h)
PSM_VERNO_MINOR := $(shell sed -n 's/^\#define.*PSM_VERNO_MINOR.*0x\([0-9]\?[0-9a-f]\+\).*/\1/p' $(build_dir)/psm.h)
PSM_LIB_MAJOR   := $(shell printf "%d" ${PSM_VERNO_MAJOR})
PSM_LIB_MINOR   := $(shell printf "%d" `sed -n 's/^\#define.*PSM_VERNO_MINOR.*\(0x[0-9a-f]\+\).*/\1/p' $(build_dir)/psm.h`)
IPATH_LIB_MAJOR := 4
IPATH_LIB_MINOR := 0
MAJOR := $(PSM_LIB_MAJOR)
MINOR := $(PSM_LIB_MINOR)

# Pacakge version information
# The desired version number comes from the most recent tag starting with "v"
TAG_VERSION ?= $(shell if [ -d .git ] ; then git describe --tags --match 'v*' --abbrev=0 2>/dev/null | sed -e 's/^v//' ; fi)
# The desired release number comes from the most recent tag starting with "r"
TAG_RELEASE ?= $(shell if [ -d .git ] ; then git describe --tags --match 'r*' --abbrev=0 2>/dev/null | sed -e 's/^r//' ; fi)
TAG_VERSION := $(if $(TAG_VERSION),$(TAG_VERSION),3.3)
TAG_RELEASE := $(if $(TAG_RELEASE),$(TAG_RELEASE),0.2)
VERSION_RELEASE := $(TAG_VERSION)-$(TAG_RELEASE)


# Try to figure out which libuuid to use. This needs to be
# done before we include buildflags.mak
PSM_USE_SYS_UUID=0
ifneq (1,${USE_PSM_UUID})
    # Check whether the uuid header file is present. The header file is
    # installed by the -devel package, which should have a dependency
    # on the package which installs the library.
    PSM_HAVE_UUID_H=$(shell if [ -f /usr/include/uuid/uuid.h ]; then echo 1; else echo 0; fi)
    ifeq (1,${PSM_HAVE_UUID_H})
       SYS_UUID_RPM_NAME=$(shell rpm -qf --qf "%{NAME} = %{VERSION}-%{RELEASE}" /usr/include/uuid/uuid.h)
       PSM_USE_SYS_UUID=1
    endif
endif

# Build the daemon only if SCIF headers are found and we are building for the host
SUBDIRS += $(and $(MIC:1=),$(PSM_HAVE_SCIF:0=),psmd)

ifneq (x86_64,$(arch))
   ifneq (i386,$(arch))
      $(error Unsupported architecture $(arch))
   endif
endif

export top_srcdir build_srcdir TMI_NAME TMI_DIR PSM_VERNO_MAJOR PSM_LIB_MAJOR \
	PSM_VERNO_MINOR PSM_LIB_MINOR IPATH_LIB_MAJOR IPATH_LIB_MINOR PSM_USE_SYS_UUID \
	DESTDIR INSTALL_SBIN_TARG INSTALL_LIB_TARG PSM_HAVE_SCIF

${TARGLIB}-objs := ptl_am/am_reqrep_shmem.o	\
		   ptl_am/am_reqrep.o		\
		   ptl_am/ptl.o			\
		   ptl_am/kcopyrwu.o		\
		   ptl_am/knemrwu.o		\
		   ptl_am/scifrwu.o		\
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

all: libs

libs: symlinks
	for subdir in $(SUBDIRS); do \
		$(MAKE) -C $$subdir ;\
	done
	$(MAKE) ${TARGLIB}.so

clean:
	rm -f _revision.c
	for subdir in $(SUBDIRS); do \
		$(MAKE) -C $$subdir $@ ;\
	done
	rm -f *.o ${TARGLIB}.*

distclean: cleanlinks clean
	rm -f *.spec *.srclist

.PHONY: symlinks
symlinks:
	@[[ -L $(build_dir)/include/linux-ppc64 ]] || \
		ln -sf linux-ppc $(build_dir)/include/linux-ppc64
	@[[ -L $(build_dir)/include/linux-x86_64 ]] || \
		ln -sf linux-i386 $(build_dir)/include/linux-x86_64

cleanlinks:
	rm -f $(build_dir)/include/linux-ppc64
	rm -f $(build_dir)/include/linux-x86_64

install: all
	for subdir in $(SUBDIRS); do \
		$(MAKE) -i -C $$subdir $@ ;\
	done
	install -D ${TARGLIB}.so.${MAJOR}.${MINOR} \
		$(DESTDIR)${INSTALL_LIB_TARG}/${TARGLIB}.so.${MAJOR}.${MINOR}
	(cd $(DESTDIR)${INSTALL_LIB_TARG} ; \
		ln -sf ${TARGLIB}.so.${MAJOR}.${MINOR} ${TARGLIB}.so.${MAJOR} ; \
		ln -sf ${TARGLIB}.so.${MAJOR} ${TARGLIB}.so) ; \
	if [ X$(MIC) != X1 ]; then \
		install -D psm.h ${DESTDIR}/usr/include/psm.h ; \
		install -D psm_mq.h ${DESTDIR}/usr/include/psm_mq.h ; \
	else \
		filelist=/opt/intel/mic/psm/psm.filelist ; \
		sed -e 's!%IPATHMAJOR%!$(IPATH_LIB_MAJOR)!g' \
			-e 's!%IPATHMINOR%!$(IPATH_LIB_MINOR)!g' \
			-e 's!%PSMMAJOR%!$(MAJOR)!g' \
			-e 's!%PSMMINOR%!$(MINOR)!g' \
		mic$$filelist.in > mic$$filelist ; \
		install -D mic/$$filelist ${DESTDIR}$$filelist ; \
		rm -f mic$$filelist ; \
	fi

tmi: libs
	$(MAKE) -C contrib/$(TMI_NAME) verbs=PSM
tmiclean:
	$(MAKE) -C contrib/$(TMI_NAME) verbs=PSM clean


.PHONY: $(RPM_NAME).spec rpms infinipath-rpm michost-rpm miccard-rpm
$(RPM_NAME).spec: $(RPM_NAME).spec.in
	sed -e 's/@VERSION@/'${TAG_VERSION}'/g' -e 's/@RELEASE@/'${TAG_RELEASE}'/g' $< > $@
	if [ X$(MIC) != X1 ]; then \
		if [ X$(PSM_USE_SYS_UUID) = X1 ]; then \
			REQUIRES="Requires: $(shell echo $(SYS_UUID_RPM_NAME) | sed -e 's/-devel//')" ; \
			REQUIRESDEVEL="Requires: $(SYS_UUID_RPM_NAME)" ; \
		fi ; \
		[ -n "$${REQUIRES}" ] && \
			sed -i -e 's%@REQUIRES@%'"$${REQUIRES}"'%g' -e 's/@PSM_UUID@//g' $@ || \
			sed -i -e '/@REQUIRES@/d' -e 's/@PSM_UUID@/USE_PSM_UUID=1/g' $@ ; \
		[ -n "$${REQUIRESDEVEL}" ] && \
			sed -i -e 's%@REQUIRES-DEVEL@%'"$$REQUIRESDEVEL"'%g' $@ || \
			sed -i -e '/@REQUIRES-DEVEL@/d' $@ ; \
	else \
		sed -i -e '/@REQUIRES@/d' \
				-e '/@REQUIRES-DEVEL@/d' \
				-e 's/@PSM_UUID@/USE_PSM_UUID=1/g' $@ ; \
	fi
rpm: distclean $(RPM_NAME).spec
	rm -rf $(RPM_BUILD_DIR)
	mkdir -p ${RPM_NAME}-${VERSION_RELEASE}
	for x in $$(/usr/bin/find . -name ".git" -prune -o \
			-name "cscope*" -prune -o \
			-name "*.spec.in" -prune -o \
			-name "${RPM_NAME}-${VERSION_RELEASE}" -prune -o \
			-name "*.orig" -prune -o \
			-name "*~" -prune -o \
			-name "#*" -prune -o \
			-name "*.rpm" -prune -o \
			-name "build" -prune -o \
			-name ".gitignore" -prune -o \
			-print); do \
		dir=$$(dirname $$x); \
		mkdir -p ${RPM_NAME}-${VERSION_RELEASE}/$$dir; \
		[ ! -d $$x ] && cp $$x ${RPM_NAME}-${VERSION_RELEASE}/$$dir; \
	done ; \
	if [ -d .git ] ; then git log -n1 --pretty=format:%H > \
		${RPM_NAME}-${VERSION_RELEASE}/COMMIT ; fi
	tar czvf ${RPM_NAME}-${VERSION_RELEASE}.tar.gz ${RPM_NAME}-${VERSION_RELEASE}
	rm -rf ${RPM_NAME}-${VERSION_RELEASE}
	mkdir -p $(RPM_BUILD_DIR)/{BUILD,BUILDROOT,RPMS,SPECS,SRPMS,SOURCES}
	rpmbuild --define "_topdir $(RPM_BUILD_DIR)" \
		$(if $(LOCAL_PREFIX),--define "install_prefix $(LOCAL_PREFIX)") \
		-ta $(RPM_NAME)-$(VERSION_RELEASE).tar.gz
	mkdir -p $(TARG_DIR)
	find $(RPM_BUILD_DIR)/RPMS -name "*.rpm" -exec cp {} $(TARG_DIR) \;
	find $(RPM_BUILD_DIR)/SRPMS -name "*.src.rpm" -exec cp {} $(TARG_DIR) \;
	rm -rf $(RPM_BUILD_DIR) $(RPM_NAME)-$(VERSION_RELEASE).tar.gz $(RPM_NAME).spec
infinipath-rpms:
	$(MAKE) PSM_HAVE_SCIF=0 TARG_DIR=$(TARG_DIR) rpm
mic-rpms:
	$(MAKE) PSM_HAVE_SCIF=1 TARG_DIR=$(TARG_DIR) rpm
miccard-rpms:
	$(MAKE) PSM_HAVE_SCIF=1 TARG_DIR=$(TARG_DIR) CC=x86_64-k1om-linux-gcc \
		LOCAL_PREFIX=/opt/intel/mic/psm rpm
rpms: infinipath-rpms mic-rpms miccard-rpms

.PHONY: package tarballs hosttarballs mictarballs
package: DESTDIR := $(TARG_DIR)/$(TARBALL_NAME)
package: distclean install
	@echo "Building $(TARBALL_NAME) tarball..."
	@if [ $(TARBALL_NAME) = mic-psm-card ]; then \
		cp -a $(top_srcdir)/mic/* $(TARG_DIR)/$(TARBALL_NAME) ; \
	fi
	@sed -e 's!%PREFIX%!$(INSTALL_PREFIX)!g' \
		-e 's!%SBINPREFIX%!$(INSTALL_SBIN_TARG)!g' \
		-e 's!%LIBPREFIX%!$(INSTALL_LIB_TARG)!g' \
		-e 's!%IPATHMAJOR%!$(IPATH_LIB_MAJOR)!g' \
		-e 's!%IPATHMINOR%!$(IPATH_LIB_MINOR)!g' \
		-e 's!%PSMMAJOR%!$(MAJOR)!g' \
		-e 's!%PSMMINOR%!$(MINOR)!g' \
		-e 's%^/%%g' \
		$(top_srcdir)/$(TARBALL_NAME).srclist.in > $(TARG_DIR)/$(TARBALL_NAME).srclist
	@sed -e 's!%PREFIX%!$(INSTALL_PREFIX)!g' \
		-e 's!%SBINPREFIX%!'$(INSTALL_SBIN_TARG)'!g' \
		-e 's!%LIBPREFIX%!'$(INSTALL_LIB_TARG)'!g' \
		-e 's!%IPATHMAJOR%!$(IPATH_LIB_MAJOR)!g' \
		-e 's!%IPATHMINOR%!$(IPATH_LIB_MINOR)!g' \
		-e 's!%PSMMAJOR%!$(MAJOR)!g' \
		-e 's!%PSMMINOR%!$(MINOR)!g' \
		-e 's%^/%%g' \
		$(top_srcdir)/$(TARBALL_NAME)-devel.srclist.in > \
			$(TARG_DIR)/$(TARBALL_NAME)-devel.srclist
	@cd $(TARG_DIR)/$(TARBALL_NAME) && \
		tar czf $(TARG_DIR)/$(RPM_NAME).tar.gz \
			-T $(TARG_DIR)/$(TARBALL_NAME).srclist && \
		tar czf $(TARG_DIR)/$(RPM_NAME)-devel.tar.gz \
			-T $(TARG_DIR)/$(TARBALL_NAME)-devel.srclist
	@rm -rf $(TARG_DIR)/$(TARBALL_NAME) $(TARG_DIR)/$(TARBALL_NAME).srclist \
		$(TARG_DIR)/$(TARBALL_NAME)-devel.srclist
infinipath-tarballs:
	$(MAKE) PSM_HAVE_SCIF=0 TARG_DIR=$(TARG_DIR) package
mic-tarballs:
	$(MAKE) PSM_HAVE_SCIF=1 TARG_DIR=$(TARG_DIR) package
miccard-tarballs:
	$(MAKE) PSM_HAVE_SCIF=1 TARG_DIR=$(TARG_DIR) CC=x86_64-k1om-linux-gcc \
		LOCAL_PREFIX=/opt/intel/mic/psm package
tarballs: infinipath-tarballs mic-tarballs miccard-tarballs

# rebuild the cscope database, skipping sccs files, done once for
# top level
cscope:
	find * -type f ! -name '[ps].*' \( -iname '*.[cfhs]' -o \
	  -iname \\*.cc -o -name \\*.cpp -o -name \\*.f90 \) -print | cscope -bqu -i -

${TARGLIB}.so: ${TARGLIB}.so.${MAJOR}
	ln -fs ${TARGLIB}.so.${MAJOR}.${MINOR} $@

${TARGLIB}.so.${MAJOR}: ${TARGLIB}.so.${MAJOR}.${MINOR}
	ln -fs ${TARGLIB}.so.${MAJOR}.${MINOR} $@

# when we build the shared library, generate a revision and date
# string in it, for easier id'ing when people may have copied the
# file around.  Generate it such that the ident command can find it
# and strings -a | grep InfiniPath does a reasonable job as well.
${TARGLIB}.so.${MAJOR}.${MINOR}: ${${TARGLIB}-objs}
	date +'char psmi_infinipath_revision[] ="$$""Date: %F %R ${rpm_extra_description}InfiniPath $$";' > ${lib_build_dir}/_revision.c
	$(CC) -c $(BASECFLAGS) $(INCLUDES) _revision.c -o _revision.o
	$(CC) $(LDFLAGS) -o $@ -Wl,-soname=${TARGLIB}.so.${MAJOR} -shared -Wl,--unique='*fastpath*' \
		${${TARGLIB}-objs} _revision.o -L$(build_dir)/ipath $(LDLIBS)
	@leaks=`nm $@ | grep ' [DT] ' | \
	 grep -v -e ' [DT] \(_edata\|_fini\|_init\|infinipath_\|ips_\|psmi\|__psm_\|__psmi_\|_rest.pr\|_save.pr\|kcopy\|knem\|scif\)'`; \
	 if test -n "$$leaks"; then echo "Build failed, leaking symbols:"; echo "$$leaks"; exit 1; fi

%.o: %.c
	$(CC) $(CFLAGS) $(INCLUDES) -c $< -o $@

.PHONY: $(SUBDIRS)

