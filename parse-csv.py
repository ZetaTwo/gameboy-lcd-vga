import csv

r = csv.reader(open('lcd-capture-full.csv'))

#['Time(s)', ' GND', ' Hsync', ' D0', ' D1', ' CLK', ' 5', ' Vsync']
for _ in range(6):
	r.next()

prev = ''
data = {}
firstHsync = True
x,y = 0,0
for line in r:
	if len(line) != 9:
		continue
	first, _, _, hsync, d0, d1, clk, _, vsync = line
	if vsync == '1':
		y = 0
		x = 0
	else:
		if hsync == '1':
			if firstHsync:
				x = 0
				y += 1
				firstHsync = False
		else:
			firstHsync = True
			if prev != clk:
				prev = clk
				if clk == '0':
					data[(x,y)] = int(d0)*2 + int(d1)
					x += 1

from PIL import Image
im = Image.new('I', (160, 144))
for xy, val in data.items():
	im.putpixel(xy, val * 0xffff/3)
#im.show()
im.save('test.png')
