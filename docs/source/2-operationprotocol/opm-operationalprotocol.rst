Operational Protocol: OPM
=========================

There are three ways to coregister with OPM:

way 1: laser scan the participants head and stylus points, then place participant in helmet, then laser scan the fiducials on the face again, followed by the 8 points on the OPM
(Check if the laser scanner would work with the OPM 8 points) (this way assumes that the participant is not moving their head within the OPM helmet)

way 2: laser scan the participant head and stylus points, then place the participant in helmet, then place HPI coils on known stylus points (must standardize those locations).
In this case, a script must be ran at beginning and end of the experiment to energize the coils with sinusoidal waves of known frequencies (follow up with fieldtrip tutorial section 2)

way 3: laser scan the participant, mark fiducials, then place participant in helmet, laser scan everything, mark fiducials
Coregister both set of fiducials