Cognitive Neuroscience class MEG demonstration
==============================================

Place and time: MEG lab in A2-008 at the 9th of October 2024, from 12:15 to 2pm

Agenda 105min total
-------------------

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

.. dropdown:: Two demonstrations: Resting state and Attention (contra-lateral) `50min`

    - Experiment 1: `Resting state: Access link to code and description <../../3-experimentdesign/experiments/1-exp-resting-state.rst>`_ `25min`
        - Two blocks: a block of 10min eyes open and a second block of 10min eyes closed
    - Experiment 2: `Attention: Access link to code and description <../../3-experimentdesign/experiments/7-attention-experiment.rst>`_ `25min`
        - the participant is asked to focus on a centered point for some duration of time
        - at some instant, a flash to a point in the far left of the visual field will appear
        - the participant must press a button when they see the flash
        - the experiment repeats itself for the right side.

.. dropdown:: Show and discuss analysis results `15min`

    - Experiment 1: `Resting state: Access link to Analysis Notebook <../../5-pipeline/notebooks/mne/resting_state_pipeline.ipynb>`_
        - Show higher alpha power in eyes closed than in eyes open in the alpha band (8-12Hz)
        - Show that this difference is better seen in the occipital region
    - Experiment 2: `Attention: Access link to Analysis Notebook <../../5-pipeline/notebooks/mne/attention_experiment.ipynb>`_
        - NA
        - NA


