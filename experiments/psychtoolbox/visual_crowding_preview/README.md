Experiment description
----------------------

[Link to experiment code](https://github.com/hzaatiti-NYU/meg-pipeline/blob/5ac461e002d1db916f57384f61e262060b9e2658/experiments/psychtoolbox/visual_crowding_preview)

Contact for this experiment:

Tasnim Ezzedin te2207@nyu.edu


Description of the experiment:

This experiment examines the crowding (the spacing between the letters within each word) and preview effects in the Arabic language, utilizing three distinct crowding values: 0, -75, and -125. Within the experiment, some values are attributed to the crowding effect as a label, respectively: 1 for -125, 2 for -75, and 3 for 0. These values are used in the naming of the images as well as in the final output of the .mat file. Within the .mat file, a column appears containing the number corresponding to the level of crowding (1, 2, or 3).
For example, SET1_conn_0_cwdg_1_1.jpg, SET1_conn_0_cwdg_2_1.jpg, etc.
Due to the nature of the arabic language being written in cursive, it has a varity of connections between letters. In the naming of the images, the 'conn' refers to the connectivity of the letters. For example, if a word has only two letters that are connected and a crowding level of 1 (i.e. -125) the name would be SET1_conn_2_cwdg_1_1.jpg.
The stimuli are made of 300 different arabic words. SET1 has a different combination of crowding values assigned to the words than SET2, however, both have the same words.

In this paradigm, participants are instructed to focus on a fixation point on the screen. Words will be presented either to the left or right of the fixation point, and participants will be required to look at the presented word when cued by the fixation point turning green. When a saccade is detected, the target word is displayed. 
The stimuli were presented as either valid or invalid, with the invalid stimulus being a flipped version of the valid one.
After that, the participant has to decide weather or not the word displayed is the same your they saw during the trial by answering the question 'Is this the last word you saw?'.
The study employs magnetoencephalography (MEG) and eye-tracking techniques to record brain activity.

The trigger channels in MEG-KIT numbering are as follows (Keep in mind that MATLAB numbering starts from 1 and not 0, so channel 224 in KIT becomes 225 in MATLAB):

- trigger channel 224: beginning of the overall experiment.
- trigger channel 225: each display of the fixation point.
- trigger channel 226: display of the preview image.
- trigger channel 227: display of the cue (fixation point turns green).
- trigger channel 228: saccade detection.
- trigger channel 229: display of the target image.
- trigger channel 230: display of the question image. 

Each trigger appears only once in each trial, except trigger channel 225, which appears each time the fixation point is presented. For example, if a fixation is not detected, channels 225 is triggered again until a fixation is detected. 
Triggers 227, 228, 229 should appear almost at the same time.

The .mat file outputs a table with relevant information about the trials, such as the crowding level of each word that was displayed, weather or not it was valid or invalid, number of connections of the letters, question answers, etc.

