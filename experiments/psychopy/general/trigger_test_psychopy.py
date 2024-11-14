from psychopy import visual, core
from pypixxlib import _libdpx as dp




# Define trigger pixels for all usable MEG channels
#trig.ch224 = [4  0  0]; %224 meg channel
#trig.ch225 = [16  0  0];  %225 meg channel
#trig.ch226 = [64 0 0]; % 226 meg channel
#trig.ch227 = [0  1 0]; % 227 meg channel
#trig.ch228 = [0  4 0]; % 228 meg channel
#trig.ch229 = [0 16 0]; % 229 meg channel
#trig.ch230 = [0 64 0]; % 230 meg channel
#trig.ch231 = [0 0  1]; % 231 meg channel



def drawPixelModeTrigger(win, pixelValue):
    # takes a pixel colour and draws it as a single pixel in the top left corner of the window
    # window must cover top left of screen to work
    # interpolate must be set to FALSE before color is set
    # call this just before flip to ensure pixel is drawn over other stimuli

    topLeftCorner = [-win.size[0] / 2, win.size[1] / 2]
    line = visual.Line(
        win=win,
        units='pix',
        start=topLeftCorner,
        end=[topLeftCorner[0] + 1, topLeftCorner[1]],
        interpolate=False,
        colorSpace='rgb255',
        lineColor=pixelValue)
    line.draw()


def RGB2Trigger(color):
    # helper function determines expected trigger from a given RGB 255 colour value
    # operates by converting individual colours into binary strings and stitching them together
    # and interpreting the result as an integer

    # return triggerVal
    return int((color[2] << 16) + (color[1] << 8) + color[0])  # dhk


def Trigger2RGB(trigger):
    # helper function determines pixel mode RGB 255 colour value based on 24-bit trigger (in decimal, base 10)
    # returns a list with R, G and B elements

    # return [red, green, blue]
    return [trigger % 256, (trigger >> 8) % 256, (trigger >> 16) % 256]  # dhk


##
# START
# Initialize connection and set up some default parameters:
dp.DPxOpen()
dp.DPxEnableDoutPixelMode()
dp.DPxWriteRegCache()

win = visual.Window(
    screen=1,  # change here to 1 to display on second screen!
    monitor=None,
    size=[1920, 1080],  # dhk: PsychoPy drew a grey (49,49,49) border around this small window
    # fullscr=False,      # therefore, top-left pixel was drawn with incorrect color.
    fullscr=False,  # using a full screen window resolved this issue
    pos=[0, 0],
    color='black',
    units="pix"
)

testvals = [0, 64, 128, 191, 255]


# KIT MEG Channels triggered via Pixel Model by setting top left pixel to a specific color
#trig.ch224 = [4  0  0]; %224 meg channel
#trig.ch225 = [16  0  0];  %225 meg channel
#trig.ch226 = [64 0 0]; % 226 meg channel
#trig.ch227 = [0  1 0]; % 227 meg channel
#trig.ch228 = [0  4 0]; % 228 meg channel
#trig.ch229 = [0 16 0]; % 229 meg channel
#trig.ch230 = [0 64 0]; % 230 meg channel
#trig.ch231 = [0 0  1]; % 231 meg channel

trigger = [[4, 0, 0], [16, 0, 0], [64, 0, 0], [0, 1, 0], [0, 4, 0], [0, 16, 0], [0, 64, 0], [0, 0, 1]]
channel_names  = ['224', '225', '226', '227', '228', '229', '230', '231']
black = [0, 0, 0]


failcount = 0
print('\nStarting Pixel Mode Test\n\nTest#\tRGB225 Color\t    Expected Dout    Returned Dout')


for i in range(5):
    for index, color in enumerate(trigger):

            print('Testing channel', channel_names[index])
            drawPixelModeTrigger(win, color)
            win.flip()
            color = black
            drawPixelModeTrigger(win, color)
            win.flip()
            core.wait(5)
            dp.DPxUpdateRegCache()

win.close()
dp.DPxDisableDoutPixelMode()
dp.DPxWriteRegCache()
dp.DPxClose()
