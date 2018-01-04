FROM gradle:jdk9 as kernel-builder

USER root

# Install the base dependencies
RUN git clone https://github.com/SpencerPark/jupyter-jvm-basekernel.git --depth 1 \
  && cd jupyter-jvm-basekernel/ \
  && gradle publishToMavenLocal

# Install the kernel
RUN git clone https://github.com/SpencerPark/IJava.git --depth 1

COPY configure-ijava-install.gradle /configure-ijava-install.gradle

RUN cd IJava/ \
  && gradle zipKernel -I /configure-ijava-install.gradle \
  && cp build/distributions/ijava-kernel.zip /ijava-kernel.zip


FROM openjdk:9.0.1-11-jdk

ENV NB_USER jovyan
ENV NB_UID 1000
ENV HOME /home/$NB_USER

RUN adduser --disabled-password \
    --gecos "Default user" \
    --uid $NB_UID \
    $NB_USER

RUN apt-get update
RUN apt-get install -y python3-pip

RUN pip3 install --no-cache-dir notebook==5.*

COPY --from=kernel-builder /ijava-kernel.zip ijava-kernel.zip

RUN unzip ijava-kernel.zip -d ijava-kernel \
  && cd ijava-kernel \
  && python3 install.py --sys-prefix

COPY . $HOME
RUN chown -R $NB_UID $HOME

USER $NB_USER