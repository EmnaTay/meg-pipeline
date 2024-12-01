Biopsychology class MEG demonstration
=====================================

Place and time: MEG lab in A2-008 at the `29th of November 2024`, from 9:15 am to 10:40 am

Agenda 85min
------------

.. dropdown:: Lab tour and general equipment presentation `10min`

    - MEG overview
    - Explain the dewar, SQUIDs sensors, liquid Helium system
    - Explain the MSR (Magnetically Shielded Room)
    - Show the computers layout and the different capabilities of the lab (eyetracker, vpixx triggers, response box, audio stimulus)
    - Present what experiments we will run on this day and the outline of the demonstration

.. dropdown:: Prepare the participant for an MEG experiment `20min`

    - Perform laser scan of headhape on the participant
    - Place participant in MSR, explain the headcoils placed on participant head
    - Perform auditory check for safety

.. dropdown:: SQUID sensors demonstration `5min`

    - Show sensitivity to noise, rapid eyeblinks, teeth pressure, phone in airplane mode on and off
    - Show marker measurement and explain their importance for source localization
    - Show reference magnetometers and explain denoising for external noise

.. dropdown:: Two demonstrations: Resting state and Auditory vs Visual `20min`

    - Experiment 1: `Resting state: Access link to code and description <../../3-experimentdesign/experiments/1-exp-resting-state.rst>`_ `5min`
        - Two blocks: a block of 10min eyes open and a second block of 10min eyes closed
    - Experiment 2: `Auditory vs Visual vs Motor: Access link to code and description <../../3-experimentdesign/experiments/9-auditory-vs-visual.rst>`_ `15min`
        - A random sequence of 150 trials with three types of stimulus (conditions): auditory 200 Hz stimulus, visual (white flash), motor (button press)


.. dropdown:: Show and discuss analysis results `20min`

    - Recap SQUID sensor operation, forward and inverse models, source reconstruction algorithms
    - Experiment 1 analysis: `Resting state: Access link to Analysis Notebook <../../5-pipeline/notebooks/fieldtrip/fieldtrip_kit_restingstate.ipynb>`_
        - Show higher alpha power in eyes closed than in eyes open in the alpha band (8-12Hz)
        - Show that this difference is better seen in the occipital region
    - Experiment 2 analysis: `Auditory vs Visual vs Motor experiment: Access link to Analysis Notebook <../../5-pipeline/notebooks/fieldtrip/fieldtrip_kit_audio_visual_motor.ipynb>`_
        - Show auditory trials activating the auditory cortex
        - Show visual trials activating the visual cortex
        - Show motor trials activating the motor cortex
