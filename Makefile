
targets:
	@echo "Try to make any of:"
	@echo
	@grep '^[^	]' Makefile

install:
	time sudo docker build  --network=host -t quartus dockerizedBuildSystem

run:
	sudo docker run --net=host --env DISPLAY=$$DISPLAY --volume="$$HOME/.Xauthority:/root/.Xauthority:rw" quartus /quartus/quartus/bin/quartus

xterm:
	sudo docker run --net=host --env DISPLAY=$$DISPLAY --volume="$$HOME/.Xauthority:/root/.Xauthority:rw" quartus xterm

flash:
	sudo docker cp eloquent_lamarr:/tmp/color_bar.svf .
	scp color_bar.svf pimento.local:/tmp/
	ssh pimento.local /home/pi/JLink_Linux_V648b_arm/JTAGLoadExe /tmp/color_bar.svf 

