FROM debian:jessie

ENV LFS=/mnt/lfs

COPY version-check.sh /
COPY wget-list /
COPY md5sums /

RUN rm -rf /bin/sh \
    && ln -s /bin/bash /bin/sh \
    && apt-get update \
    && apt-get install -y wget build-essential bison gawk m4 texinfo \
    && mkdir -v $LFS \
    && mkdir -v $LFS/sources \
    && chmod -v a+wt $LFS/sources \
    && wget --input-file=wget-list --continue --directory-prefix=$LFS/sources \
    && mkdir -v $LFS/tools \
    && ln -sv $LFS/tools /

# add lfs user/group
RUN groupadd lfs \
    && useradd -s /bin/bash -g lfs -m -k /dev/null lfs \
    && echo "lfs:lfs" | chpasswd \
    && chown -v lfs $LFS/tools \
    && chown -v lfs $LFS/sources

COPY .bash_profile /home/lfs
COPY .bashrc /home/lfs

RUN chown -v lfs /home/lfs/.bash_profile \
    && chown -v lfs /home/lfs/.bashrc

USER lfs

ENV LC_ALL=POSIX \
  LFS_TGT=x86_64-lfs-linux-gnu \
  PATH=/tools/bin:/bin:/usr/bin

RUN  tar -xf $LFS/sources/binutils-2.30.tar.xz -C /tmp/ && \
  pushd /tmp/binutils-2.30 && \
  mkdir -v build && \
  cd build && \
  ../configure     \
    --prefix=/tools            \
    --with-sysroot=$LFS        \
    --with-lib-path=/tools/lib \
    --target=$LFS_TGT          \
    --disable-nls              \
    --disable-werror && \
  make && \
  mkdir -pv /tools/lib && \
  ln -sv lib /tools/lib64 && \
  make install && \
  popd && \
  rm -rf /tmp/binutils-*

RUN tar -xf $LFS/sources/gcc-7.3.0.tar.xz -C /tmp/ && \
  pushd /tmp/gcc-7.3.0 && \
  tar -xf $LFS/sources/mpfr-4.0.1.tar.xz && \
  mv -v mpfr-4.0.1 mpfr && \
  tar -xf $LFS/sources/gmp-6.1.2.tar.xz && \
  mv -v gmp-6.1.2 gmp && \
  tar -xf $LFS/sources/mpc-1.1.0.tar.gz && \
  mv -v mpc-1.1.0 mpc && \
  for file in gcc/config/{linux,i386/linux{,64}}.h; do \
    cp -uv $file{,.orig}; \
    sed -e 's@/lib\(64\)\?\(32\)\?/ld@/tools&@g' -e 's@/usr@/tools@g' $file.orig > $file; \
    echo -e "\n#undef STANDARD_STARTFILE_PREFIX_1\n#undef STANDARD_STARTFILE_PREFIX_2\n#define STANDARD_STARTFILE_PREFIX_1 \"/tools/lib/\"\n#define STANDARD_STARTFILE_PREFIX_2 \"\"" >> $file; \
    touch $file.orig; \
  done && \
  sed -e '/m64=/s/lib64/lib/' -i.orig gcc/config/i386/t-linux64 && \
  mkdir -v build && \
  cd build && \
  ../configure                                       \
    --target=$LFS_TGT                              \
    --prefix=/tools                                \
    --with-glibc-version=2.11                      \
    --with-sysroot=$LFS                            \
    --with-newlib                                  \
    --without-headers                              \
    --with-local-prefix=/tools                     \
    --with-native-system-header-dir=/tools/include \
    --disable-nls                                  \
    --disable-shared                               \
    --disable-multilib                             \
    --disable-decimal-float                        \
    --disable-threads                              \
    --disable-libatomic                            \
    --disable-libgomp                              \
    --disable-libmpx                               \
    --disable-libquadmath                          \
    --disable-libssp                               \
    --disable-libvtv                               \
    --disable-libstdcxx                            \
    --enable-languages=c,c++ && \
  make && \
  make install && \
  popd && \
  rm -rf /tmp/gcc-*



