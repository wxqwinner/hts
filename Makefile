#
# Makefile for autoai.
#
# @history:
#  2020-10-16 wangxq Created.
#
# Copyright (c) 2020~ wangxq
#


# Includes the project configurations
include project.conf

# Validating project variables defined in project.conf
ifndef project_name
$(error Missing project_name. Put variables at project.conf file)
endif
ifndef src_dir
$(error Missing src_dir. Put variables at project.conf file)
endif
ifndef platform
$(error Missing platform. Put variables at project.conf file)
endif

# Hyper parameter
mode             ?= debug
examples_dir     ?= examples
platform_dir     ?= src/platform
test_dir         ?= tests
test_name        := ${project_name}_test
benchmark_dir    ?= benchmark
benchmark_name   := ${project_name}_benchmark
githash          := $(shell git rev-parse --short HEAD)
version          := $(shell git describe --tags --abbrev=0)
builddate        := $(shell date "+%Y-%m-%d %H:%M:%S")
profiling        ?= 0

ifneq (x$(shell git diff ${version} | head -n 1), x)
$(warning "The workspace has changed relative tag ${version}!")
version := ${version}+dev
endif

# Build Mode [release | debug]
ifeq (${mode}, release)
	drflags := -O3 -w
else ifeq (${mode}, debug)
	drflags := -g3 -Wall -Wextra -pedantic -DDEBUG=1 -v
else
$(error "The mode ${mode} error, only [release|debug] is supported!")
endif

# Multi-platform support
ifeq (${platform}, imx6q) # imx6q
	tool_prefix     := arm-poky-linux-gnueabi-
	tool_dir        := /opt/poky/1.4.1/sysroots/i686-pokysdk-linux/usr/bin/cortexa9hf-vfp-neon-poky-linux-gnueabi
	rootfs          := /opt/poky/1.4.1/sysroots/cortexa9hf-vfp-neon-poky-linux-gnueabi
	platform_rootfs := /opt/platforms/imx6q/rootfs
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      := -mthumb
	add_cxxflags    :=
	add_cppflags    := --sysroot=$(rootfs) -march=armv7-a -fpermissive -mfpu=neon -mfloat-abi=hard -ftree-vectorize -ffast-math -fopenmp -I${platform_rootfs}/include
	# Add Libs
	add_ldlibs      := -lncnn -lstdc++ -ldl -lpthread -lm
	add_ldflags     := -L${platform_rootfs}/lib
else ifeq (${platform}, yulong810a) # yulong810a
	tool_prefix     := arm-linux-gnueabihf-
	tool_dir        := /opt/platforms/yulong810a/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin
	rootfs          :=
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      := -I$(rootfs)/usr/include -fmessage-length=0 -fpermissive -mfpu=neon  -mfloat-abi = hard -ftree-vectorize
	add_cxxflags    := -I$(rootfs)/usr/include -fmessage-length=0 -fpermissive -mfpu=neon  -mfloat-abi = hard -ftree-vectorize
	# Add Libs
	add_ldlibs      := -lstdc++ -ldl -lm -lpthread
	add_ldflags     := 
else ifeq (${platform}, x1000)
	tool_prefix     := mips-linux-gnu-
	tool_dir        := /opt/platforms/x1000/release_halley2_v1.0-20151221/toolchains/mips-gcc472-glibc216/bin
	rootfs          := /opt/platforms/x1000/release_halley2_v1.0-20151221/toolchains/mips-gcc472-glibc216/mips-linux-gnu/libc
	platform_rootfs := /opt/platforms/x1000/rootfs
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      := -fmessage-length=0
	add_cxxflags    := -fmessage-length=0
	add_cppflags    := --sysroot=$(rootfs) -march=mips32 -mabi=32 -mfp32 -D WEBRTC_POSIX -I${platform_rootfs}/include
	# Add Libs
	add_ldlibs      := -lncnn -lm -lpthread
	add_ldflags     := -L${platform_rootfs}/lib
else ifeq (${platform}, e2000q) # e2000q
	tool_prefix     := aarch64-none-linux-gnu-
	tool_dir        := /opt/platforms/e2000q/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/bin
	rootfs          := /opt/platforms/e2000q/gcc-arm-9.2-2019.12-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc
	platform_rootfs := /opt/platforms/e2000q/rootfs
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      := -fmessage-length=0
	add_cxxflags    := -fmessage-length=0  -fpermissive
	add_cppflags    := --sysroot=$(rootfs) -march=armv8-a -D WEBRTC_POSIX -I${platform_rootfs}/include
	# Add Libs
	add_ldlibs      := -lncnn -lstdc++ -ldl -lpthread -lm
	add_ldflags     := -L${platform_rootfs}/lib
else ifeq (${platform}, rk3308) # rk3308
	tool_prefix     := aarch64-linux-gnu-
	tool_dir        := /opt/platforms/rk3308/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/bin
	rootfs          := /opt/platforms/rk3308/gcc-linaro-6.3.1-2017.05-x86_64_aarch64-linux-gnu/aarch64-linux-gnu/libc
	platform_rootfs := /opt/platforms/rk3308/rootfs
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      := -fmessage-length=0
	add_cxxflags    := -fmessage-length=0 -fpermissive
	add_cppflags    := --sysroot=$(rootfs) -march=armv8-a -I${platform_rootfs}/include
	# Add Libs
	add_ldlibs      := -lncnn -fopenmp -lstdc++ -ldl -lpthread -lm
	add_ldflags     := -L${platform_rootfs}/lib
else ifeq (${platform}, s905x3) # s905x3
	tool_prefix     := aarch64-none-linux-gnu-
	tool_dir        := /opt/platforms/s905x3/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/bin
	rootfs          := /opt/platforms/s905x3/gcc-arm-10.2-2020.11-x86_64-aarch64-none-linux-gnu/aarch64-none-linux-gnu/libc
	platform_rootfs := /opt/platforms/s905x3/rootfs
	run_envs        := LD_LIBRARY_PATH=/opt/platforms/s905x3/rootfs/lib:$$LD_LIBRARY_PATH /usr/bin/qemu-aarch64-static -L ${rootfs}
	# Add Flags
	add_asflags     := 
	add_arflags     := rcs
	add_cflags      := -fmessage-length=0
	add_cxxflags    := -fmessage-length=0 -fpermissive
	add_cppflags    := --sysroot=$(rootfs) -march=armv8-a -D WEBRTC_POSIX -I${platform_rootfs}/include
	# Add Libs
	add_ldlibs      := -ltflite -lncnn -lstdc++ -ldl -fopenmp -lpthread -lm
	add_ldflags     := -L${platform_rootfs}/lib
else ifeq ($(platform), gcc75) # gcc75
	tool_prefix     := arm-linux-gnueabihf-
	tool_dir        := /opt/platforms/gcc75/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/bin
	rootfs          := /opt/platforms/gcc75/gcc-linaro-7.5.0-2019.12-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc
	platform_rootfs := /opt/platforms/gcc75/rootfs
	run_envs        := LD_LIBRARY_PATH=/opt/platforms/gcc75/rootfs/lib:$$LD_LIBRARY_PATH /usr/bin/qemu-arm-static -L ${rootfs}
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      := -fmessage-length=0 -mthumb
	add_cxxflags    := -fmessage-length=0 -fpermissive
    add_cppflags    := --sysroot=$(rootfs) -march=armv7-a -mfloat-abi=hard -mfpu=neon -I${platform_rootfs}/include -ffast-math -ftree-vectorize -fopenmp
	# Add Libs
	add_ldlibs      := -ltflite -lncnn -lm -lstdc++ -ldl -lpthread -fopenmp
	add_ldflags     := -L${platform_rootfs}/lib
else ifeq ($(platform), rk3308_32) # rk3308_32
	tool_prefix     := arm-linux-gnueabihf-
	tool_dir        := /opt/platforms/rk3308_32/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf/bin
	rootfs          := /opt/platforms/rk3308_32/gcc-linaro-6.3.1-2017.02-x86_64_arm-linux-gnueabihf/arm-linux-gnueabihf/libc
	platform_rootfs := /opt/platforms/rk3308_32/rootfs
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      := -fmessage-length=0 -mfpu=neon -mfloat-abi=hard
	add_cxxflags    := -fmessage-length=0 -fpermissive -mfpu=neon -mfloat-abi=hard
	add_cppflags    := --sysroot=$(rootfs) -I${platform_rootfs}/include
	# Add Libs
	add_ldlibs      := -lncnn -lstdc++ -ldl -lpthread -lm
	add_ldflags     := -L${platform_rootfs}/lib
else ifeq (${platform}, x64) # x64 PLATFORM
	tool_prefix     :=
	tool_dir        := /usr/bin
	rootfs          :=
	platform_rootfs := /opt/platforms/x64/rootfs
	run_envs        := 
	# Add Flags
	add_asflags     :=
	add_arflags     := rcs
	add_cflags      :=
	add_cxxflags    :=
	add_cppflags    := -D WEBRTC_POSIX -I${platform_rootfs}/include
	# Add Libs
	add_ldlibs      := -ltflite -lncnn -lstdc++ -ldl  -lpthread -lm -fopenmp
	add_ldflags     := -L${platform_rootfs}/lib
else
$(error "The platform ${platform} is not supported!")
endif

build_dir    := build/${platform}/${mode}
obj_dir      := ${build_dir}/obj
bin_dir      := ${build_dir}/bin
log_dir      := ${build_dir}/log
lib_dir      := ${build_dir}/lib
out_dir      := ${build_dir}/out
version_dir  := $(shell echo "${version}" | sed 's/\./_/g')_${githash}
releases_dir := ${project_name}_${platform}_${mode}_${version_dir}
c_std        := -std=gnu99
cxx_std      := -std=c++11
includes     := ./src
warnings     := #-Wall -Werror
c_warnings   := ${warnings}
cxx_warnings := ${warnings}

CC           := ${tool_dir}/${tool_prefix}gcc
CXX          := ${tool_dir}/${tool_prefix}g++
AS           := ${tool_dir}/${tool_prefix}as
AR           := ${tool_dir}/${tool_prefix}ar
RANLIB       := ${tool_dir}/${tool_prefix}ranlib
LD           := ${tool_dir}/${tool_prefix}ld
STRIP        := ${tool_dir}/${tool_prefix}strip
ASFLAGS      := ${add_asflags}
CFLAGS       := ${drflags} ${add_cflags} ${c_std} ${c_warnings}
CXXFLAGS     := ${drflags} ${add_cxxflags} ${cxx_std} ${cxx_warnings}
CPPFLAGS     := -c -fPIC ${add_cppflags} ${addprefix -I,${includes}}
ARFLAGS      := rcs
LDLIBS       := ${add_ldlibs}
LDFLAGS      := -L./${lib_dir} ${add_ldflags}
BIN_LDLIBS   := -ltflite -lstdc++ -lportaudio -ldl -lasound -lpthread -lm -fopenmp
BIN_LDFLAGS  := ${add_ldflags}
MACROFLAGS   := -D GITHASH='"${githash}"' -D VERSION='"${version}"' -D BUILDDATE='"${builddate}"'

ifeq ($(profiling), 1)
    MACROFLAGS += -DPROFILING
endif

define collect_examples_object
$(patsubst ${examples_dir}/$1/%,${obj_dir}/${examples_dir}/$1/%.o, $(shell find ${examples_dir}/$1 -name '*.cpp' -or -name '*.c' -or -name '*.S'))
endef

define collect_benchmark_object
$(patsubst ${benchmark_dir}/$1/%,${obj_dir}/${benchmark_dir}/$1/%.o, $(shell find ${benchmark_dir}/$1 -name '*.cpp' -or -name '*.c' -or -name '*.S'))
endef

# sources
example_sources     := $(shell find ${examples_dir} -name '*.cpp' -or -name '*.c')
platform_sources    := $(shell find ${platform_dir} -name '*.cpp' -or -name '*.c')
benchmark_sources   := $(shell find ${benchmark_dir} -name '*.cpp' -or -name '*.c')
test_sources        := $(shell find ${test_dir} -name '*.cpp' -or -name '*.c')
common_sources      := $(foreach dir, ${src_dir}, $(shell find $(dir) -maxdepth 1 -name '*.cpp' -or -name '*.c' -or -name '*.S'))
all_sources         := ${example_sources} ${test_sources} ${common_sources}
example_objects     := $(example_sources:%=$(obj_dir)/%.o)
platform_objects    := $(platform_sources:%=$(obj_dir)/%.o)
benchmark_objects   := $(benchmark_sources:%=$(obj_dir)/%.o)
test_objects        := $(test_sources:%=$(obj_dir)/%.o)
common_objects      := $(common_sources:%=$(obj_dir)/%.o)
all_objects         := ${example_objects} ${benchmark_objects} ${test_objects} ${common_objects}
all_depfiles        := $(patsubst %.o,%.d,${all_objects})
binary_name         := ${name}
# ifeq (${platform}, x64)
binary_name         := $(shell find examples -type f \( -name "*.c" -o -name "*.cpp" \) -exec dirname {} \; | awk -F'/' '/examples\//{print $$NF}' | sort -u)
# endif
binaries            := $(addprefix ${bin_dir}/, ${binary_name})
benchmark_name      := $(shell ls ${benchmark_dir})
benchmarks          := $(addsuffix _benchmark, $(addprefix ${bin_dir}/, ${benchmark_name}))
alib                := lib${lib_name}.a
slib                := lib${lib_name}.so

ifeq (${link_priority}, static)
	link_lib        := :$(alib)
	pre_run         := ${run_envs}
else
	link_lib        := ${lib_name}
	pre_run         := LD_LIBRARY_PATH=${lib_dir} ${run_envs}
endif

all: ${lib_dir}/${alib} merge_libraries  ${binaries} ${benchmarks} $(bin_dir)/${test_name} out
$(foreach m,${binary_name},$(eval ${bin_dir}/$m: $(call collect_examples_object,$m) ${platform_objects}))
$(foreach m,${benchmark_name},$(eval ${bin_dir}/$m_benchmark: $(call collect_benchmark_object,$m) ${platform_objects}))

debug:
	@echo ${platform}
	@echo ${binary_name}
	@echo ${benchmark_name}
	@echo ${benchmarks}
	@echo ${pre_run}
	@echo ${mode}
	@echo ${platform_rootfs}
	@echo ${third_party_objects}
	@echo ${platform_objects}
	@echo $(shell git describe --tags --abbrev=0)

# rules
$(bin_dir)/%:
	mkdir -p $(dir $@)
	${CC} $^ -o $@ -L./${lib_dir} -l${link_lib} ${BIN_LDFLAGS} ${BIN_LDLIBS}

$(bin_dir)/${test_name}: ${test_objects} ${common_objects}
	mkdir -p $(dir $@)
	${CC} ${LDFLAGS} $^ -o $@ ${LDLIBS}

$(lib_dir)/%.a: ${common_objects}
	mkdir -p $(dir $@)
	${AR} ${ARFLAGS} $@ $^

$(lib_dir)/%.so: ${common_objects}
	mkdir -p $(dir $@)
	${CC} -shared ${LDFLAGS} $^ ${LDLIBS} -o $@

# c++ source
$(obj_dir)/%.cpp.o: %.cpp
	mkdir -p $(dir $@)
	${CXX} ${MACROFLAGS} ${CPPFLAGS} ${CXXFLAGS} $< -o $@

# c source
$(obj_dir)/%.c.o: %.c
	mkdir -p $(dir $@)
	${CC} ${MACROFLAGS} ${CPPFLAGS} ${CFLAGS} $< -o $@

# assembly
$(obj_dir)/%.S.o: %.S
	mkdir -p $(dir $@)
	${CC} ${MACROFLAGS} ${ASFLAGS} ${CPPFLAGS} ${CFLAGS} $< -o $@
#$(AS) $(ASFLAGS) -c $< -o $@

# merge_libraries
merge_libraries:
	@echo "*********************************************merge_libraries"
	cp ${platform_rootfs}/lib/libtflite.a $(lib_dir)
	cp ${platform_rootfs}/lib/libncnn.a $(lib_dir)
	@bash tools/merge_libraries.sh $(lib_dir)/libai.a $(lib_dir)/libncnn.a $(lib_dir)/${alib}
	rm $(lib_dir)/${alib}
	rm $(lib_dir)/libtflite.a
	rm $(lib_dir)/libncnn.a
	mv $(lib_dir)/libai.a $(lib_dir)/${alib}


# pack
pack:
	@echo "*********************************************pack"
	$(STRIP) --strip-unneeded ${binaries}
	upx ${binaries}

run:
	@echo "*********************************************run"
	${pre_run} ./${bin_dir}/${name} ${args}

# test
test:
	@echo "*********************************************tests"
	./$(bin_dir)/$(test_name)

# benchmark
bench:
	@echo "*********************************************benchmark"
	./$(bin_dir)/${benchmark_name}

# out
out:
	@echo "*********************************************releases"
	cp ${bin_dir}/${name} ${bin_dir}/${project_name}
	mkdir -p ${out_dir}/${releases_dir}
	mkdir -p ${out_dir}/${releases_dir}/examples
	mkdir -p ${out_dir}/${releases_dir}/include/autoai
	mkdir -p ${out_dir}/${releases_dir}/include/autoai/utils
	cp -r ${bin_dir} ${out_dir}/${releases_dir}
	cp -r ${lib_dir} ${out_dir}/${releases_dir}
	cp ./src/*.h ${out_dir}/${releases_dir}/include/autoai
	cp ./src/utils/types.h ${out_dir}/${releases_dir}/include/autoai/utils
	cp -r ${examples_dir}/* ${out_dir}/${releases_dir}/examples

# releases
releases:
	@echo "*********************************************releases"
	tar -cJf ${out_dir}/${releases_dir}.xz -C ${out_dir}/ ${releases_dir}
	cd ${out_dir}/${releases_dir}/ && zip -r ../${releases_dir}.zip *

profile:
	@echo "*********************************************profile"
	mkdir -p $(log_dir)
	LD_LIBRARY_PATH=${lib_dir} valgrind \
		--track-origins=yes \
		--leak-check=full \
		--show-leak-kinds=all \
		--show-error-list=yes \
		--leak-resolution=high \
		--log-file=$(log_dir)/$@.log \
		${pre_run} ./${bin_dir}/${name} ${args}
	LD_LIBRARY_PATH=${lib_dir} valgrind \
		--tool=massif \
		--stacks=yes \
		--pages-as-heap=yes \
		--massif-out-file=$(log_dir)/massif.out.log \
		${pre_run} ./${bin_dir}/${name} ${args}
	# ms_print $(log_dir)/massif.out.log
	@echo -en "\nCheck the log file: $(log_dir)/$@.log\n"

show:
	@echo ${binaries}
	@echo ${tool_dir}
	@echo ${tool_prefix}
	@echo ${platform}

help:
	@echo
	@echo " make [target] [options]"
	@echo
	@echo " target:"
	@echo "     all                  Builds the app.  This is the default target."
	@echo "     clean                Clean all the objects, apps and dependencies."
	@echo "     run                  Run the binary."
	@echo "     profile              Performance analysis."
	@echo "     pack                 Compress the binary."
	@echo "     releases             Release project."
	@echo "     help                 Prints this message."
	@echo " options:"
	@echo "     mode=<mode>          Specify <mode> build (debug default)."
	@echo "     name=<bin>       Specify <bin> to execute."
	@echo "     platform=<platform>  Specify <platform> build (x64 default)."
	@echo "                                                                    "
	@echo


.PHONY:clean

clean:
	@echo "*********************************************clean"
	@rm -rf ${build_dir}/*

-include ${all_depfiles}
