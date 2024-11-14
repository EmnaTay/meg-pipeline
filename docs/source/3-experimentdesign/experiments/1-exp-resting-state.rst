.. _resting_state_exp:

Experiments example 1 (Psychtoolbox): Resting state
---------------------------------------------------



- Resting state experiment: Using PsychToolBox the following script executes a resting state experiment.

The participant is asked to close their eyes for some time, then to open their eyes while fixing a centered shape for a same duration.
Two triggers are sent from the 'Datapixx3' to the KIT-MEG on channels 224 (closing eyes) and 225 (opening eyes).
The code for the experiment can be found here: Source file link
`resting_state_meg.m <https://github.com/hzaatiti-NYU/meg-pipeline/blob/main/experiments/psychtoolbox/general/resting_state_meg.m>`_.

.. dropdown:: Resting state task code

    .. literalinclude:: ../../../../experiments/psychtoolbox/general/resting_state_meg.m
      :language: matlab


Analysis results
^^^^^^^^^^^^^^^^

The notebook provides analysis results after running the experiment on a participant (Sub-01).

`Link to my notebook <../../5-pipeline/notebooks/mne/resting_state_pipeline.ipynb>`_