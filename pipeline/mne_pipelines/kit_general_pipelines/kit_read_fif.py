import mne


file_path = 'emptyroom_10.con'

raw = mne.io.read_raw_kit(file_path, preload=True, verbose=False)

a=1