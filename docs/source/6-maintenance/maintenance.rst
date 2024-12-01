*************************
Maintenance of MEG system
*************************

Checks to be made
-----------------

Helium level

* Every two days check Helium Level it should be higher than 50%
* Check the ATP and ATL gas flow and pressure
    * If low Helium pressure (Low G FLOW on the ATL) then
        * Remove the hose between ATP and ATL
        * Check if helium is passing through the hose
        * Plug the hose again, see if G Flow increases
        * Restart the ATL from the green button on the rear panel


Data retrieval from ATP and ATL for diagnostic
----------------------------------------------
When the ATP and ATL helium recovery system exhibits low gas flow or unusual temperature/pressure,
contact the references below and provide them the following data

#. Retrieve data from ATP and ATL by opening an FTP connection to 10.224.44.200 and 10.224.44.201
#. Connect to the NYU Abu Dhabi VPN
#. Use the following information username: qd, password: 79653
#. Navigate to the */StorageCard/DAT_Files/* directory for each of the previous IP addresses, send the latest *.dat* files



.. note::
    documentation in the link: `QD Documentation for Data retrieval <https://nyu.box.com/v/qd-documentation>`_
    Sheet to be filled by maintenance team for Helium levels `Helium Filling Sheet <https://docs.google.com/spreadsheets/d/14-yHq_U9Un0HXIno1-XeL928Vmv2yO2f/edit#gid=1063352714>`_


Check air pressure every month

-	The air pressure inside the meg can be not so good, it must be 0.7, 0.8 this could be a compressor problem
-	When the air pressure is low, the door could be stuck


Working hours of the ATL and ATP compressors are seen directly on the mini screen display on each compressor, this correspond to the number of hours the compressor has been operational.


MSR Door:

- Test the emergency button every week
- Test if the pressure release when using the emergency button is getting heavier or not releasing pressure as it is supposed to be
- If using the manual handle, make sure that to reset the door, you need to put the handle in the original position or else the door won’t reset



Helium refill process
---------------------

- Bijoy (bs4233@nyu.edu) will indicate that Helium tanks are needed, he will communicate to Neelima Dinil (nd1508@nyu.edu) this need
- Hadi will receive an email to approve the Helium tanks needs
- Hadi will confirm the needs by replying and putting Osama, Bijoy, Neelima and Nyavili Miyanda (vili.mulemba@nyu.edu) in copy
- Nileema will schedule with Bijoy the delivery of the tanks
- Bijoy will schedule the Helium refilling as necessary
- When a new PO is needed to cover for the dewar costs, issue one using the CTP Requisition form then inform Jinna


The ATL tank (QD recovery system) will be used to refill the dewar. However, when the tanks inside ATL room are full, we need to evacuate some Helium into the lab
so that the ATL tank starts to fill again when placed into the recovery system.



.. csv-table:: ATL compressor Helium filling sheet
   :header-rows: 1
   :file: helium_refill_data.csv


Request for new equipment/IT or Helium Dewar
--------------------------------------------

CTP members can raise requests to purchase new needed equipment, lab supplies and so on.

.. note::
    CTP member request for equipment/Helium dewar `CTP Requisition Form <https://docs.google.com/forms/d/e/1FAIpQLSewUcPh-me_TIw0wTxYVOP-v93ibHpKusiT3CpmfuWLgafvkw/viewform>`_


Helium Refill steps
-------------------

- The Helium measurement system behind the dewar when it indicates that the helium level is below 20%, means a refill should happen
- Bijoy come to check physically the measurement if it is below 20% using the display
- The percentage should not go below 20%, when the level starts approaching 20%, a refill is needed
- Every monday Bijoy and his team will perform the Helium refill
    - The team comes at 9am UAE time on monday
    - If the level became below 20% before the next monday, a refill will happen before that monday
- The team will take the measurements and log them into the excel sheet
    - of the Helium level at the dewar
    - The ATL level the L Volume from the display
    - The AT recovery compressor Output Pressure
    - The ATP Pinput and P output
    - cylinder levels
    - the gas counting meter in the back of the helium room
    - chilled water temperature there is two thermostat
- The ATL system is shut down using power off button from the touch screen on the ATL
        - mode then stop
        - after 10 seconds it stops the ATL compressor will also be off
        - remove the right and left pipes from the back of the ATL and the electric power plug and the gas pipe, (4 pipes in total)
        - then move the red atl cylinder to the back of the dewar
        - take the needle image
        - the needle is put into the ATL cylinder and a flashing and a little nois eand the fog image
        - The T diode on the atl if it is above 3, then we need to evacuate some of the helium with the second valve image
        - When it is below 3 (we know from the display there is a built in battery on the ATL that keeps pwoering it on) then we can procceed with the needle
        - before refilling we put the apollo handle to transsfer counter clockwise 90 degrees
        - if the pressure is high some release wqill hapen at this point from th e valve near the apollo handle
        - we might partially close the valve (image) when the presure is very high, just for a few minutes to avoid a strong evacuation of the high pressure
        - after the pressure is gone, then fully open back agai (red handle to the south direction)
- from the back of the dewar you remove the cap (image)
- and then put the needle from the short end into the dewar removed cap thingie (image), then make it tight
- then ATL need to start the transfer mode
- and then press Start green square button on the Automatic Helium Supplier device (image)
- Wait a few minutes then the Automatic Heliun Supplier level should start increasing
- During this time, the liquid helium is being transfered to the dewar, at the same time the vapor will channel through the tubes back to the 4 cylinders
- when the 4 cylinders are full, (the gage pressure shows 70  check unit), the light becomes red (image)
- if we need to fill more liquid helium and the cylinders are full, then we need to empty some vapor using the black handle above the KIT racks (image), we keep open until the filling is finished
- when the helium level is 90-95% then
- The stopping criterion is either the cylinders are full or the helium level became 90-95%, if the atl is below 20 liter then we should stop the filling
- To stop the filling, put the ATL on stop transfer switch, and then on the automatic helium supplier press "Stop" (red square button) image
- everyone wears the cryogenic glove during the maintenance intervention
- then disconnect the needle from the upper side and from the atl side, put back the needle in its place
- then move the ATL system back to the helium chamber, then connect the ATL again, before starting again the ATL, put back the yellow handle to BPC
- then turn the ATL on and the mode liquefication
- Make sur ethe black handle above the rack is well closed, and the cap on the dewar back is back
- update the excel sheet wit the new helium values
- ever 3 month the water filter is replaced image

To fill from an external helium dewar from a supplier the procedure is a little different.





Before the helium refilling, record the following data in the logbook
amount of liquid helium in the MEG in %
gas counter
medium pressure (MP) hub screen : outlet P
ATP screen: volume of purified gas, pressure (P) input, P output
ATL screen: L volume
Stop ATL by pressing MODE → STOP → OK
Disconnect gas inlet, supply, return and electrical connector from the read side of ATL. Release wheel brake if necessary
Switch the yellow valve handle to TRANSFER position (horizontally)
Move ATL to MEG room
Press green START button on the MEG level-meter
Put on protective face shields and adequate cryo-gloves
Release and remove the plug from the transfer port, carefully insert the transfer line into the port. Do not bend the transfer line ! It must remain vertical all the time. Stop inserting when a thick portion of the transfer line passes through the sealing washer. tighten the washer.
Slowly lower the transfer line until white plume comes from the other side.
Insert this side in the MEG inlet port, seal the port by tightening the washer if necessary
Slowly lower the transfer line into ATL until it touches the bottom, then pull it 3-5 cm back.
Start refill by pressing MODE → TRANSFER → 5. Press CANCEL if compressor activation is requested. Touch the screen again to return to the main menu.
Observe Helium level change in ATL (decreasing) and MEG (increasing)
. Refill should be terminated when one or more of the following conditions are fulfilled:
ATL helium level below 10L
MEG helium level above 90%
Red overfill light on the wall is activated
Lift the transfer line by 60-70cm. Wait approximately 30 seconds and unplug the line from the MEG port. Then quickly remove the transfer line from ATL.
Press the red STOP button on the MEG level-meter and green POWER button on the wall box on  MEG.
Move ATL back into the soundproof enclosure, activate the wheel brake.
Switch the yellow valve handle to BPC position (vertically).
Connect the gas inlet, supply, return and electrical connector from the rear side of ATL.
Start ATL by pressing MODE → LIQUEFY → SLOW
Now record the data in the logbook
amount of liquid helium in the MEG in %
gas counter
medium pressure (MP) hub screen : outlet P
ATP screen: volume of purified gas, pressure (P) input, P output
ATL screen: L volume
Procedure is complete

Important: If the difference between P input and P output on ATP screen is 4PSI or higher, please make sure, medium pressure (MP)  Hub outlet pressure is below 5 bar and start ATP regeneration by pressing MODE → REGENERATION → LOW TEMPERATURE REGENERATION → OK.



Contacts table
--------------

.. list-table::
   :widths: 25 25 25 25
   :header-rows: 1

   * - Name
     - Email
     - Number
     - Role
   * - Hadi Zaatiti
     - hz3752@nyu.edu
     - +971 56 275 4921
     - Research Scientist
   * - Lawrence Torres
     - ljt7767@nyu.edu
     - NA
     - NA
   * - Qiang Zhang
     - qz19@nyu.edu
     - NA
     - NA
   * - QD Helium Recovery
     - heliumrecovery@qd-europe.com
     - NA
     - NA
   * - QD Konstantin Voigt
     - voigt@qd-europe.com
     - NA
     - NA
   * - QD Tobias Adler
     - adler@qd-europe.com
     - NA
     - NA
   * - Ahmed Ansari
     - aa7703@nyu.edu
     - NA
     - Helium store manager (Primary contact for getting Helium tanks)
   * - Mohammad Rakib
     - mr5527@nyu.edu
     - NA
     - Logistics and Sanitation Coordinator