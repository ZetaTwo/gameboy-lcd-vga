install:
	sudo docker build -t quartus .

xconnect:
	sudo docker run --net=host --env="DISPLAY" --volume="$HOME/.Xauthority:/root/.Xauthority:rw" quartus xterm

flash:
	sudo docker cp eloquent_lamarr:/tmp/color_bar.svf .
	scp color_bar.svf pimento.local:/tmp/
	ssh pimento.local /home/pi/JLink_Linux_V648b_arm/JTAGLoadExe /tmp/color_bar.svf 

