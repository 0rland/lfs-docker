# lfs-docker
Building LFS system in docker container step by step

Build Linux From Scratch in Docker container

Once upone 5 years I'm building LFS (Linux from Scratch) system several times.
To do so, I used separate old linux box with several partitions.
Docker is the boss of virtualization tech. and I've upgraded RAM to 16G,
I'm going to use containers as much as possible.
LFS building is a good flow for that.

I'm building LFS image step by step.
To start the process, LFS needs some existing linux system with dev. environment.
I created lfs:01 image from debian:jessie.
It needs to install buil-essential and some other small changes to pass version-check.sh test.

RUN rm -rf /bin/sh \
    && ln -s /bin/bash /bin/sh
COPY version-check.sh /

RUN apt-get update \
    && apt-get install -y wget build-essential bison gawk m4 texinfo

Instead of create lfs partition I mounted lfs volume to /mnt/lfs.

# create volume in specific host folder
docker volume create --name lfs -o type=none -o device=/home/alex/Projects/lfs/lfs -o o=bind

# use volume in container
docker run --name lfs -v lfs:/mnt/lfs -ti lfs:02 bash



# check build environment
bash /version-check.sh

# check sources
pushd $LFS/sources
md5sum -c /md5sums
popd


# build temp tools

It needs to create lfs account and do all the actions under it.

# It needs to setup a password for that lfs user
`echo "lfs:lfs" | chpasswd`

# switch to lfs user
`USER lfs`


Linux's
    core-utils
    find-utils
    tar
check max path in one of its tests on configure stage.
It fails in docker container by default.
Besides, the container is locked, so, it's impossible to remove it.
Workaround is to move part of that long path to another point in filesystem,
then remove both.
Before configure coreutils apply this patch:

`patch -Np1 -i $LFS/sources/coreutils.getcwd-path-max.patch`

```
--- coreutils-7.2.original/configure    2009-04-01 01:34:13.000000000 +1300
+++ coreutils-7.2/configure 2015-05-25 12:50:39.616794241 +1200
@@ -19177,6 +19177,7 @@
 #include <sys/stat.h>
 #include <sys/types.h>
 #include <fcntl.h>
+#include <stdio.h>

 #ifndef AT_FDCWD
 # define AT_FDCWD 0
@@ -19304,6 +19305,13 @@

     /* Try rmdir first, in case the chdir failed.  */
     rmdir (DIR_NAME);
+    /* Getting rid of the very bottom dirs inside a Docker container is tricky */
+    if (chdir ("../..") < 0) exit (errno);
+    rename (DIR_NAME"/"DIR_NAME, "c");
+    rename (DIR_NAME, "d");
+    rmdir ("c");
+    rmdir ("d");
+    /* Now for the rest */
     for (i = 0; i <= n_chdirs; i++)
       {
    if (chdir ("..") < 0)
```

Other similar projects:

https://github.com/pbret/lfs-docker/blob/master/lfs-toolchain/Dockerfile

docker build --tag=lfs-systemd/lfs-toolchain:7.9 --build-arg PROC=$(nproc) lfs-toolchain

docker run lfs:XX tar -cJf - -C /mnt/lfs . > lfs-toolchain.tar.xz



https://github.com/reinterpretcat/lfs

docker rm lfs ;                                    \
docker build --tag lfs . &&                        \
sudo docker run -it --privileged --name lfs lfs && \
sudo docker cp lfs:/tmp/lfs.iso .


http://www.linuxfromscratch.org/lfs/view/stable/chapter04/settingenvironment.html

