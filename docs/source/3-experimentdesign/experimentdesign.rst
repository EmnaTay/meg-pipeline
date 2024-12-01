.. _design_experiment:

Implementing your experiment
============================

Purpose
-------

This section provides information to help you out designing your MEG experiment.
What is meant by experiment, is the stimuli involving usually visual and auditory or other perception-type stimulus.
The experiment defines the timing of display of the stimuli, tracks responses from the participants and controls the different settings related
to the content being presented to the participant.
This section also provides the requirements that should be met to run your experiment in the NYUAD MEG Lab.
Roughly speaking, the experiment should be designed in a way such that:

- when the participant performs the experiment, a specific behavior in the brain is triggered due to the stimulus from the experiment
- which you should "beleive" that, when MEG/EEG measurements are obtained, would nicely `highlight` the specific behavior

Therefore, the design of an experiment should come after extensive research about the phenomena that we would like to characterize.


There are three tools primarily used for designing the experiment used in NYUAD MEG Lab

- Psychtoolbox: a MATLAB based library (all NYUAD affiliated students/employees have access to MATLAB)
- Presentation: a powerful license based software (a license is available at the NYUAD MEG LAB)
- Psychopy: an open source Python library with both GUI based design and code based design


Defining the hardware needs for your experiment
------------------------------------------------

Depending on your study you might need different require different hardware, the following use cases can be identified:

- Show visual stimuli to participants for a certain amount of time
- Allow participant to send their input via buttons
- Get eyetracking information from the eyetracker device
- Provide audio to the user
- Record audio from the user's voice

Hardware involved in experiment
-------------------------------

- Propixx
- Datapixx
- Eyetracker

Datapixx pixel mode `Pixel mode <https://docs.vpixx.com/vocal/defining-triggers-using-pixel-mode>`_.

The eyetracker sends three different signals to the MEG/EEG channels:

- The X-coordinates of the eye as function of time
- The Y-coordinates of the eye as function of time
- The Area of the pupil of the eye as function of time


Files produced by the experiment design
---------------------------------------


- An experiment in PsychToolBox is a `.m` MATLAB script.
- Presentation provides a `.exp` file, an experiment file.
- PsychoPy is a `.py` experiment file.

If using python library PsychoPy:

* Open the file with .psyexp extension
* you can run from within the psycopy builder the experiment file with .psyexp extension c



Pixel mode experiments
----------------------

All experiments that uses the Vpixx pixel mode should follow these rules:

- Once the experiment script is run, the experiment should land on an `Introduction page` that requires a button press to be able to continue by the project owner (the participant should not be able to continue through this page)
- Prior to landing on the `Introduction page` within your script, you should deactivate the Vpixx Pixel Mode, otherwise there could be false trigger events in the data recording


"Presentation" based experiments
--------------------------------

Experiments coded in "Presentation" do not enable the Vpixx pixel mode by default.
If your experiment uses Pixel Mode (i.e., you are using the color of the top left pixel of the screen as a condition to send triggers), you must run the `enablepixelmode.m` script.
Find the script under  `experiments/psychtoolbox/general/enablepixelmode.m <https://github.com/hzaatiti-NYU/meg-pipeline/blob/main/experiments/psychtoolbox/general/enablepixelmode.m>`_


KIT experiment length
---------------------

The maximum length of a KIT `.con` file recording can be 4000 seconds = 66 minutes, this is the maximum total length of the recording.
Therefore, the design of your experiment that requires more then this time, should be performed in blocks each of maximum total duration of ideally 55 minutes (to have a safety time margin).
When the recording reaches the final length, a new recording must start (this is described in the KIT operational protocol).


KIT system testing triggers
---------------------------

If you are in the testing phase of your experiment and would like to test the triggers, you can do so without locking the sensors.
Simply open `MEG160` and then `Acquire -> MEG Measurement`, then run your experiment from the stimulus computer and observe channels 224 -> 231 to check for trigger signals.
