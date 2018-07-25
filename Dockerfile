FROM ubuntu:xenial
MAINTAINER Chidi Ugonna<chidiugonna@email.arizona.edu>

# install pre-reqs
RUN apt-get update && apt-get install -y \	
	nano \
	wget \
	curl \
        dc \
	lsb-core \
	python-pip \
        libx11-6 \
        libgl1 \
        libgtk-3-0 \
        libgtk-3-dev \
        libsm6 \
        libxext6 \
        libxt6 \
        mesa-common-dev \
        freeglut3-dev \
        zlib1g-dev \
        libpng-dev \
        expat \
        unzip \
        libeigen3-dev \
        zlib1g-dev \
        libqt4-opengl-dev \
        libgl1-mesa-dev \
        software-properties-common
RUN add-apt-repository universe
RUN apt-get update && apt-get install -y \
        tcsh \
        xfonts-base \
        python-qt4 \
        gsl-bin \
        gnome-tweak-tool \
        libjpeg62 \
        xvfb \
        vim \
        libglu1-mesa-dev \
        libglw1-mesa   \
        libxm4 \
        netpbm
RUN apt-get update && apt-get install -y \
        hdf5-tools \
        openmpi-bin \
        openmpi-doc \
        libopenmpi-dev \
        gfortran 

RUN pip install numpy
RUN pip install scipy
RUN pip install nibabel
RUN pip install networkx==1.11
RUN pip install pyBIDS

ENV LD_LIBRARY_PATH /usr/local/cuda/lib64:/.singularity.d/libs:/usr/lib:$LD_LIBRARY_PATH
ENV FSLDIR /opt/fsl
ENV PATH $FSLDIR/bin:$PATH
ENV PATH $FSLDIR/bin/FSLeyes:$PATH
ENV PATH=$FSLDIR/bin/eddypatch:$PATH
ENV BXHVER bxh_xcede_tools-1.11.1-lsb30.x86_64
ENV BXHBIN /opt/$BXHVER
ENV RSFMRI /opt/rsfmri_python
ENV PATH $BXHBIN/bin:$PATH
ENV PATH $BXHBIN/lib:$PATH
ENV PATH $RSFMRI/bin:$PATH
ENV PATH /usr/local/cuda/bin:$PATH


RUN cd /tmp
RUN echo "LC_ALL=en_US.UTF-8" >> /etc/environment
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
RUN echo "LANG=en_US.UTF-8" > /etc/locale.conf
RUN locale-gen en_US.UTF-8

WORKDIR /tmp
RUN wget "https://developer.nvidia.com/compute/cuda/8.0/Prod2/local_installers/cuda_8.0.61_375.26_linux-run"
RUN mkdir -p nvidia_installers
RUN chmod +x cuda_8.0.61_375.26_linux-run
RUN ./cuda_8.0.61_375.26_linux-run -extract=`pwd`/nvidia_installers
RUN rm cuda_8.0.61_375.26_linux-run
WORKDIR /tmp/nvidia_installers
RUN rm cuda-samples*
RUN rm NVIDIA-Linux*
RUN ./cuda-linux64-rel-8.0.61-21551265.run -noprompt
WORKDIR /tmp
RUN rm -R nvidia_installers

RUN wget https://cmake.org/files/v3.10/cmake-3.10.0-rc1.tar.gz
RUN tar xz -f cmake-3.10.0-rc1.tar.gz
RUN rm cmake-3.10.0-rc1.tar.gz
RUN chmod +x /tmp/cmake-3.10.0-rc1
WORKDIR /tmp/cmake-3.10.0-rc1
RUN ./configure
RUN make
RUN make install
RUN ./bootstrap --prefix=/usr
RUN make
RUN make install

WORKDIR /tmp
RUN wget http://www.vtk.org/files/release/7.1/VTK-7.1.1.tar.gz
RUN tar xz -f VTK-7.1.1.tar.gz
RUN rm VTK-7.1.1.tar.gz
WORKDIR VTK-7.1.1
RUN cmake .
RUN make
RUN make install

WORKDIR /opt
RUN wget https://www.dropbox.com/s/chetucmygqyz992/fsl-5.0.11-sources.tar.gz
RUN tar xz -f fsl-5.0.11-sources.tar.gz
RUN rm fsl-5.0.11-sources.tar.gz
RUN chmod -R 777 fsl
WORKDIR ${FSLDIR}
RUN sed -i 's/#FSLCONFDIR/FSLCONFDIR/g' ${FSLDIR}/etc/fslconf/fsl.sh && \
 sed -i 's/#FSLMACHTYPE/FSLMACHTYPE/g' ${FSLDIR}/etc/fslconf/fsl.sh && \
 sed -i 's/#export FSLCONFDIR FSLMACHTYPE/export FSLCONFDIR FSLMACHTYPE/g' ${FSLDIR}/etc/fslconf/fsl.sh && \
 . ${FSLDIR}/etc/fslconf/fsl.sh && \
 if [ ! -d ${FSLDIR}/config/${FSLMACHTYPE} ]; then cp -r ${FSLDIR}/config/linux_64-gcc4.8 ${FSLDIR}/config/${FSLMACHTYPE}; fi && \
 sed -i "s#scl enable devtoolset-2 -- c++#c++#g" ${FSLDIR}/config/${FSLMACHTYPE}/systemvars.mk && \
 sed -i "s#CUDA_INSTALLATION = /opt/cuda-7.5#CUDA_INSTALLATION = /usr/local/cuda-8.0#g" ${FSLDIR}/config/${FSLMACHTYPE}/systemvars.mk && \
 sed -i "s#VTKDIR_INC = /home/fs0/cowboy/var/caper_linux_64-gcc4.4/VTK7/include/vtk-7.0#VTKDIR_INC = /usr/local/include/vtk-7.1/#g" ${FSLDIR}/config/${FSLMACHTYPE}/externallibs.mk && \
 sed -i "s#VTKDIR_LIB = /home/fs0/cowboy/var/caper_linux_64-gcc4.4/VTK7/lib#VTKDIR_LIB = /usr/local/lib/#g" ${FSLDIR}/config/${FSLMACHTYPE}/externallibs.mk && \
 sed -i "s#VTKSUFFIX = -7.0#VTKSUFFIX = -7.1#g" ${FSLDIR}/config/${FSLMACHTYPE}/externallibs.mk && \
 sed -i "s#{LIBRT}#{LIBRT} -ldl#g" ${FSLDIR}/src/mist-clean/Makefile && \
 sed -i "s#lpng -lz#lpng -lz -lm#g" ${FSLDIR}/src/miscvis/Makefile && \
 ./build && \
 sed -i "s#dropprivileges=1#dropprivileges=0#g" ${FSLDIR}/etc/fslconf/fslpython_install.sh && \
 ${FSLDIR}/etc/fslconf/fslpython_install.sh
RUN mkdir -p $FSLDIR/bin/eddypatch
WORKDIR ${FSLDIR}/bin/eddypatch
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/patches/eddy-patch-fsl-5.0.11/centos6/eddy_cuda8.0 && \
 chmod +x eddy_cuda8.0 && \
 wget https://fsl.fmrib.ox.ac.uk/fsldownloads/patches/eddy-patch-fsl-5.0.11/centos6/eddy_openmp && \
 chmod +x eddy_openmp
WORKDIR ${FSLDIR}/bin
RUN wget https://fsl.fmrib.ox.ac.uk/fsldownloads/fsleyes/FSLeyes-latest-ubuntu1604.zip && \
 unzip FSLeyes-latest-ubuntu1604.zip && \
 rm FSLeyes-latest-ubuntu1604.zip

WORKDIR /tmp
RUN wget http://users.fmrib.ox.ac.uk/~moisesf/Probtrackx_GPU/CUDA_8.0/probtrackx2_gpu.zip && \
 unzip probtrackx2_gpu.zip && \
 rm -f probtrackx2_gpu.zip && \
 mv probtrackx2_gpu $FSLDIR/bin

RUN mkdir /tmp/bedpost
WORKDIR /tmp/bedpost
RUN wget http://users.fmrib.ox.ac.uk/~moisesf/Bedpostx_GPU/CUDA_8.0/bedpostx_gpu.zip && \
 unzip bedpostx_gpu.zip && \
 rm -f bedpostx_gpu.zip && \
 cp /tmp/bedpost/bin/* $FSLDIR/bin && \
 cp /tmp/bedpost/lib/* $FSLDIR/lib && \
 rm -r /tmp/bedpost && \
 sed -i 's\#!/bin/sh\#!/bin/bash\g' $FSLDIR/bin/bedpostx_postproc_gpu.sh

WORKDIR /tmp
ENV BXHVER bxh_xcede_tools-1.11.1-lsb30.x86_64
ENV BXHLOC=7384
RUN wget "http://www.nitrc.org/frs/download.php/${BXHLOC}/${BXHVER}.tgz" && \
 wget "https://wiki.biac.duke.edu/_media/biac:analysis:rsfmri_python.tgz" && \
 tar -xzf ${BXHVER}.tgz -C /opt && \
 mv biac:analysis:rsfmri_python.tgz rsfmri_python.tgz && \
 tar -xzf rsfmri_python.tgz  -C /opt && \
 rm rsfmri_python.tgz && \
 rm $BXHVER.tgz

RUN mkdir /opt/bin
RUN chmod -R 777 /opt
WORKDIR /opt/bin 
#sed could not effectively change file as described above - sp just create a new copy of resting_pipeline 
COPY ./src/resting_pipeline.py /opt/rsfmri_python/bin
COPY ./src/startup.sh .
COPY ./src/runfeat-1.py .
COPY ./src/statusfeat.py .
COPY ./src/make_fsl_stc.py .
COPY ./src/fsl_sub $FSLDIR/bin
COPY ./src/readme .
COPY ./src/version .


RUN mkdir /opt/output
RUN mkdir /opt/input
RUN mkdir /opt/work
WORKDIR /opt/data

# Replace 1000 with your user / group id
RUN export uid=1000 gid=1000 && \
    mkdir -p /home/developer && \
    mkdir -p /etc/sudoers.d && \
    echo "developer:x:${uid}:${gid}:Developer,,,:/home/developer:/bin/bash" >> /etc/passwd && \
    echo "developer:x:${uid}:" >> /etc/group && \
    echo "developer ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/developer && \
    chmod 0440 /etc/sudoers.d/developer && \
    chown ${uid}:${gid} -R /home/developer

ENV USER developer
ENV HOME /home/developer

#Source FSL configuration (no bash profile exists in neurodebian so just copy over)
RUN cp $FSLDIR/etc/fslconf/fsl.sh ~/.bash_profile
RUN /bin/bash -c ". ~/.bash_profile"
RUN echo ". ~/.bash_profile" >> ~/.bashrc

ENTRYPOINT ["/opt/bin/startup.sh"]
