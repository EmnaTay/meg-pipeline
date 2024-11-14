
import mne

# Load the raw .fif file
raw = mne.io.read_raw_fif('20241015_105744_sub-phantom_file-test_raw.fif', preload=True)


# Get the channel information from the raw object
channel_info = raw.info['chs']

# Extract calibration (scaling) factors for all sensors
calibration_factors = [ch['cal'] for ch in channel_info]

# Display the first few calibration factors
print(calibration_factors[:10])
