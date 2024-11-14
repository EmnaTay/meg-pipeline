import os

import numpy as np
import mne
from mne.time_frequency import tfr_morlet
import matplotlib
import matplotlib.pyplot as plt

MEG_DATA = os.getenv('MEG_DATA')

CLOSED_DATA_PATH = "resting-state\sub-01\meg-kit\sub-01_01-eyes-closed-raw.fif"
OPEN_DATA_PATH = "resting-state\sub-01\meg-kit\sub-01_02-eyes-open-raw.fif"

CLOSED_DATASET_PATH  = os.path.join(MEG_DATA, CLOSED_DATA_PATH)
OPEN_DATASET_PATH = os.path.join(MEG_DATA, OPEN_DATA_PATH)

VISU = False

matplotlib.use('TkAgg')

# Load your raw data (using an example dataset here)
raw_closed = mne.io.read_raw_fif(CLOSED_DATASET_PATH, preload=True)

raw_open = mne.io.read_raw_fif(OPEN_DATASET_PATH, preload=True)



# Print raw data info

print(raw_closed.info)

if VISU:
    # Print the selected channels in 3D for KIT
    fig = mne.viz.plot_alignment(
        raw_closed.info,
        dig=False,
        eeg=False,
        surfaces=[],
        meg=["helmet", "sensors"],
        coord_frame="meg",
    )
    mne.viz.set_3d_view(fig, azimuth=50, elevation=90, distance=0.5)


    # For a 2D topographic plot of the sensor locations
    raw_closed.plot_sensors(kind='topomap', show_names=True);


    # For a 3D plot, you can also do:
    fig = raw_closed.plot_sensors(kind='3d', show_names=True)




    # Plot the first 5 seconds of the data
    raw_closed.plot(start=0, duration=5)

    print(raw_closed.info.get_channel_types())

    print(raw_closed.ch_names)

    channel_name = 'MISC 001'
    raw_picked = raw_closed.copy().pick_channels([channel_name])
    scalings = {'misc':0.1}

    raw_picked.plot(scalings = scalings, duration=315, start=0, n_channels=1)


crop_raw_closed = raw_closed.copy()
crop_raw_closed.crop(100, 250)

crop_raw_open = raw_open.copy()
crop_raw_open.crop(100, 250)

# Select a specific channel by name
#channel_name = 'MEG 194'  # Change this to the name of the channel you want to plot
#channel_index = crop_raw_closed.ch_names.index(channel_name)

# Define frequencies of interest
frequencies = np.arange(1, 51, 1)  # Frequencies from 1 to 50 Hz

# Define the number of cycles in each frequency
n_cycles = frequencies / 2.  # Different number of cycles per frequency




# Bad channels if existent
#channels_with_issues = ['MEG 091', 'MEG 056', 'MEG 059', 'MEG 148', 'MEG 053', 'MEG 067', 'MEG 102', 'MEG 137', 'MEG 154', 'MEG 181', 'MEG 182', 'MEG 183', 'MEG 157']

# Mark bad channels
#crop_raw_closed.info['bads'] = channels_with_issues
#crop_raw_open.info['bads'] = channels_with_issues

#crop_raw_closed = crop_raw_closed.copy().drop_channels(crop_raw_closed.info['bads'])
#crop_raw_open = crop_raw_open.copy().drop_channels(crop_raw_closed.info['bads'])



# Define the duration of each epoch (in seconds)
epoch_duration = 2  # 2 sec

epochs_closed = mne.make_fixed_length_epochs(crop_raw_closed, duration=epoch_duration, preload=True)
epochs_open = mne.make_fixed_length_epochs(crop_raw_open, duration=epoch_duration, preload=True)


averaged_epochs_closed = epochs_closed.average(picks = ['meg', 'eeg'])
averaged_epochs_open = epochs_closed.average(picks = ['meg', 'eeg'])

# Plot sensors with kind='select' to allow channel selection
#fig, selected_channels = mne.viz.plot_sensors(raw_closed.info, kind='select', show_names=True)



#selected_channels = [element for element in selected_channels if element not in channels_with_issues]

#print("Selected channels:", selected_channels)

#selected_channels = ['MEG 149', 'MEG 208', 'MEG 194', 'MEG 205', 'MEG 129', 'MEG 170', 'MEG 165']

# Pick the specific channels
#epochs_closed.pick(selected_channels)
#epochs_open.pick(selected_channels)





# Plot PSD for cleaned data with labels
fig, (ax1, ax2) = plt.subplots(2, 1, figsize=(8, 6), sharex=True)


# Plot PSD for the first 1 minute (eyes closed)
# First half is eyes closed

#epochs_closed.plot_psd(fmin=1, fmax=40, ax=ax1, color='blue', show=False, average=True, spatial_colors=False, line_alpha=0.5, dB=True, xscale='log')
#epochs_open.plot_psd(fmin=1, fmax=40, ax=ax2, color='blue', show=False, average=True, spatial_colors=False, line_alpha=0.5, dB=True, xscale='log')

averaged_epochs_closed.plot_psd(fmin=1, fmax=40, ax=ax1, color='blue', show=False, average=True, spatial_colors=False, line_alpha=0.5, dB=True, xscale='log')
averaged_epochs_open.plot_psd(fmin=1, fmax=40, ax=ax2, color='blue', show=False, average=True, spatial_colors=False, line_alpha=0.5, dB=True, xscale='log')


# from mne import Epochs
#
# Epochs.average

print('Plotting psd')

# Add labels
ax1.set(title='Power Spectral Density (Eyes Closed)', xlabel='Frequency (Hz)', ylabel='Power Spectral Density (dB)')
ax2.set(title='Power Spectral Density (Eyes Open)', xlabel='Frequency (Hz)', ylabel='Power Spectral Density (dB)')

# Show the plot
plt.tight_layout()
plt.show()

averaged_epochs_closed['visual/right'].plot_psd_topomap()

plt.show()

# Compute the power spectral density (PSD) using Morlet wavelets
freqs = np.logspace(*np.log10([1, 40]), num=50)  # Define frequency range





n_cycles = freqs / 2

plt.show()

power_closed = tfr_morlet(averaged_epochs_closed, freqs=freqs, n_cycles=n_cycles, return_itc=False, average=True)


# Plot the PSD
fig, ax = plt.subplots(figsize=(10, 6))
power_closed.plot([0], baseline=None, mode='logratio', title='Average power', axes=ax, show=False)

plt.show()

b = 1