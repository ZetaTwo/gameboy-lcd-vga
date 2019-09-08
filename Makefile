

DOCKER := sudo docker run --net=host --volume="$$PWD/src/:/src/:rw"
XFLAGS := --env "DISPLAY=$$DISPLAY" --volume="$$HOME/.Xauthority:/root/.Xauthority:rw"

targets:
	@echo "Try to make any of:"
	@echo
	@grep '^[^	]' Makefile | grep -v ':='

install:
	time sudo docker build  --network=host -t quartus dockerizedBuildSystem

bash:
	$(DOCKER) -ti quartus bash

quartus_gui:
	$(DOCKER) $(XFLAGS) quartus bash -c '/quartus/quartus/bin/quartus /src/*.qpf'

xterm:
	$(DOCKER) $(XFLAGS) quartus xterm

compile:
	$(DOCKER) -ti quartus bash -c '/quartus/quartus/bin/quartus_cmd /src/*.qpf -c gameboy_lcd_to_vga'

flash:
	$(DOCKER) quartus bash -c '/quartus/quartus/bin/quartus_cpf -c -q 10MHz -g 3.3 -n p /src/*.cdf /src/toflash.svf'
	scp src/toflash.svf pimento.local:/tmp/toflash.svf
	ssh pimento.local /home/pi/JLink_Linux_V648b_arm/JTAGLoadExe /tmp/toflash.svf

src/%.hex : src/%.bin
	objcopy -I binary -O ihex $< $@
