from PIL import Image
import random

def create_image(input_color):
    img = Image.new('RGBA', (144,256), color=input_color)
    return img

def rgb2hex(rgb_color):
    return "#{:02x}{:02x}{:02x}".format(rgb_color[0], rgb_color[1], rgb_color[2])

color = (0,0,0)
hex_name = rgb2hex(color)
img = create_image(color)
img.save('sample/'+hex_name+'.png')

i = 0
for i in range(10):
    r = random.randint(0, 255)
    g = random.randint(0, 255)
    b = random.randint(0, 255)
    color = (r,g,b)
    hex_name = rgb2hex(color)
    img = create_image(color)
    img.save('sample/'+hex_name+'.png')