FROM i686/ubuntu
RUN apt-get update
RUN apt-get install -y xterm

# http://download.altera.com/akdlm/software/acds/11.0sp1/208/standalone/11.0sp1_quartus_free_linux.sh
ADD 11.0sp1_quartus_free_linux.sh /tmp/11.0sp1_quartus_free_linux.sh

RUN bash /tmp/11.0sp1_quartus_free_linux.sh --keep ; rm /11.0sp1_quartus_free_linux/altera_installer/bin/libpng12.so.0 /tmp/11.0sp1_quartus_free_linux.sh ; /11.0sp1_quartus_free_linux/linux_installer/quartus_free/install --auto /quartus ; /quartus/quartus/bin/quartus_sh --qinstall -qda /11.0sp1_quartus_free_linux/devices/subscription/cyclone.qda ; rm -r /11.0sp1_quartus_free_linux
