#!/bin/bash

if [[ -z ${ARCH} ]]; then
    echo -e "(*) ARCH not defined\n"
    exit 1
fi

if [[ -z ${TARGET_SDK} ]]; then
    echo -e "(*) TARGET_SDK not defined\n"
    exit 1
fi

if [[ -z ${SDK_PATH} ]]; then
    echo -e "(*) SDK_PATH not defined\n"
    exit 1
fi

if [[ -z ${BASEDIR} ]]; then
    echo -e "(*) BASEDIR not defined\n"
    exit 1
fi

# ENABLE COMMON FUNCTIONS
if [[ ${APPLE_TVOS_BUILD} -eq 1 ]]; then
    . ${BASEDIR}/build/tvos-common.sh
else
    . ${BASEDIR}/build/ios-common.sh
fi

# PREPARE PATHS & DEFINE ${INSTALL_PKG_CONFIG_DIR}
LIB_NAME="libsrt"
set_toolchain_clang_paths ${LIB_NAME}

# PREPARING FLAGS
BUILD_HOST=$(get_build_host)
export CFLAGS=$(get_cflags ${LIB_NAME})
export CXXFLAGS=$(get_cxxflags ${LIB_NAME})
export LDFLAGS=$(get_ldflags ${LIB_NAME})
export PKG_CONFIG_LIBDIR=${INSTALL_PKG_CONFIG_DIR}

cd ${BASEDIR}/src/${LIB_NAME} || exit 1

make distclean 2>/dev/null 1>/dev/null

# DISABLE building of examples manually
${SED_INLINE} 's/examples tests//g' ${BASEDIR}/src/${LIB_NAME}/Makefile*

# RECONFIGURE IF REQUESTED
if [[ ${RECONF_libsrt} -eq 1 ]]; then
    autoreconf_library ${LIB_NAME}
fi

make clean
rm CMakeCache.txt
case ${ARCH} in
x86-64)
  TARGET_ARCH="x86_64"
  ;;
x86-64-mac-catalyst)
  TARGET_ARCH="x86_64"
  ;;
*)
  TARGET_ARCH="${ARCH}"
  ;;
esac
#git clone git@github.com:x2on/OpenSSL-for-iPhone.git

#cd OpenSSL-for-iPhone

#./build-libssl.sh --archs="${TARGET_ARCH}" || exit 1

#export IOS_OPENSSL="${BASEDIR}/src/${LIB_NAME}/OpenSSL-for-iPhone/bin/iPhoneOS13.6-arm64.sdk"

#cd ..
./configure --cmake-c-compiler=$(xcrun --sdk iphoneos -find clang) --cmake-c++-compiler=$(xcrun --sdk iphoneos -find clang++) --cmake-cxx-flags="-isystem ${SDK_PATH} -arch ${TARGET_ARCH} -target $(get_target_host) -fembed-bitcode" --cmake-c-flags="-isysroot ${SDK_PATH} -arch ${TARGET_ARCH} -target $(get_target_host) -fembed-bitcode" --sysroot="${SDK_PATH}" --disable-encryption --disable-apps --cmake-osx-sysroot="${SDK_PATH}"

#cmake -DCMAKE_INSTALL_PREFIX="${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME}" -DENABLE_C_DEPS=ON -DENABLE_SHARED=OFF -DENABLE_STATIC=ON

#./configure --cmake-prefix-path=$IOS_OPENSSL --use-openssl-pc=OFF --cmake-toolchain-file=scripts/iOS.cmake

make -j$(get_cpu_count) || exit 1

mkdir ${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME}/

cp -r ${BASEDIR}/src/${LIB_NAME}/include ${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME}/

mkdir ${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME}/lib/

cp ${BASEDIR}/src/${LIB_NAME}/libsrt.a ${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME}/lib/

# MANUALLY COPY PKG-CONFIG FILES
rm ./srt.pc

echo -e "prefix=${BASEDIR}/prebuilt/$(get_target_build_directory)/${LIB_NAME}\n\
exec_prefix=\${prefix}\n\
libdir=\${exec_prefix}/lib\n\
includedir=\${prefix}/include\n\n\
Name: srt\n\
Description: SRT library set\n\
Version: 1.4.1\n\
Libs: -L\${libdir} -lsrt\n\
Libs.private:  -lc++\n\
Cflags: -I\${includedir} -I\${includedir}/srt\n\
Requires.private:\n" 1>>"./srt.pc"

cp ./srt.pc ${INSTALL_PKG_CONFIG_DIR} || exit 1
cp ./srt.pc ${INSTALL_PKG_CONFIG_DIR}/libsrt.pc || exit 1






