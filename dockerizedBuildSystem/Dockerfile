FROM i686/ubuntu
RUN apt-get update
RUN apt-get install -y xterm

# http://download.altera.com/akdlm/software/acds/11.0sp1/208/standalone/11.0sp1_quartus_free_linux.sh
ADD 11.0sp1_quartus_free_linux.sh /tmp/11.0sp1_quartus_free_linux.sh

RUN bash -v /tmp/11.0sp1_quartus_free_linux.sh --keep || true
# remove libpng and try again, will work.
RUN rm /11.0sp1_quartus_free_linux/altera_installer/bin/libpng12.so.0
RUN bash /11.0sp1_quartus_free_linux/setup --standalone --install=quartus_free
