
targets:
	@echo "Try to make any of:"
	@echo
	@grep '^[^	]' Makefile

install:
	time sudo docker build  --network=host -t quartus dockerizedBuildSystem

bash:
	sudo docker run -it --net=host --volume="$$PWD/src/:/src/:rw" quartus bash

quartus_gui:
	sudo docker run --net=host --volume="$$PWD/src/:/src/:rw" --env DISPLAY=$$DISPLAY --volume="$$HOME/.Xauthority:/root/.Xauthority:rw" quartus bash -c '/quartus/quartus/bin/quartus /src/*.qpf'

xterm:
	sudo docker run --net=host --volume="$$PWD/src/:/src/:rw" --env DISPLAY=$$DISPLAY --volume="$$HOME/.Xauthority:/root/.Xauthority:rw" quartus xterm

flash:
	scp src/*.svf pimento.local:/tmp/toflash.svf
	ssh pimento.local /home/pi/JLink_Linux_V648b_arm/JTAGLoadExe /tmp/toflash.svf

