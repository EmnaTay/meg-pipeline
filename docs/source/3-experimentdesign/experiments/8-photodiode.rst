Experiment example 8: Using Photodiode
----------------------------------------------

In this experiment, a photodiode is used to estimate the lag in time between a trigger signal sent from the Vpixx system to
the KIT DAQ computers. With experiments that requires milliseconds precision with a lag time below 5 ms, it is ideal to use a photodiode to correct
for the lag.
The estimated lag measured with the below experiment, that involved 1000 trials, is around 8.5ms on average with a variance of 0.4.

Authors: Gayathri Satheesh <gs2750@nyu.edu>, Hadi Zaatiti <hadi.zaatiti@nyu.edu>

.. dropdown:: Photodiode experiment

    .. literalinclude:: ../../../../experiments/psychtoolbox/attention/meg_attention_task.m
      :language: matlab