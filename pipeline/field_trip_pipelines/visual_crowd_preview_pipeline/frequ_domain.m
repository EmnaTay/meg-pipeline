
confile = 'MEG data\Sub_002_01_vcp.con'; % Ensure correct file path to MEG data

matFilePath = fullfile('MATLAB Data', 'Sub_002_vcp.mat');
load_data_MAT = load(matFilePath); 
data_MAT = load_data_MAT.EXP.data; % extracting the table from the structure

cfg =[];
cfg.dataset = confile;
cfg.coilaccuracy = 0;
data_MEG = ft_preprocessing(cfg);


%%

% Set parameters
channelOfInterest = 'AG001';       
samplingRate = 1000;           
signal = data_MEG.trial{1}(1, :);  

% Perform FFT
n = length(signal);           
Y = fft(signal);               
P2 = abs(Y/n);               
P1 = P2(1:floor(n/2)+1);      
P1(2:end-1) = 2*P1(2:end-1);   

% Compute frequency axis
f = samplingRate * (0:(n/2)) / n;  % Frequency axis for plotting

% Plot the Power Spectrum
figure;
plot(f, P1);
xlabel('Frequency (Hz)');
ylabel('Amplitude');
title(['Power Spectrum of raw signal' ]);


%% Cleaning: Inspect and exclude trials for artefacts

% Parameters
samplingRate = 1000;        % Replace with your actual sampling rate in Hz
lowCutoff = 4;              % Lower bound of bandpass filter (4 Hz)
highCutoff = 40;            % Upper bound of bandpass filter (40 Hz)
notchFreq = 50;

% Original raw signal for comparison
rawSignal = signal;

% Design a bandpass filter from 4 to 40 Hz
[b, a] = butter(2, [lowCutoff, highCutoff] / (samplingRate / 2), 'bandpass');  % 2nd order Butterworth bandpass filter

% Apply the bandpass filter to the raw signal
filteredSignal = filtfilt(b, a, rawSignal);  % Zero-phase filtering


% Optional Notch Filter (50 Hz, to remove power line interference)
wo = 50 / (samplingRate / 2);  % Normalize frequency for notch
bw = wo / 35;                         % Bandwidth around the notch frequency
[b, a] = iirnotch(wo, bw);            % Design the notch filter
cleanedSignal1 = filtfilt(b, a, filteredSignal);


%% Filtering out 62 Hz Peak


% Notch filter at 60 Hz to remove power line interference
notchFreq = 62;         % Center frequency for the notch
wo = notchFreq / (samplingRate / 2);  % Normalize frequency for notch
bw = wo / 35;           % Bandwidth around the notch frequency
[b, a] = iirnotch(wo, bw);  % Design the notch filter

% Apply the notch filter to the bandpass filtered signal
cleanedSignal = filtfilt(b, a, cleanedSignal1);  % Apply zero-phase filtering

% Perform FFT on the cleaned signal
Y_cleaned = fft(cleanedSignal);
P2_cleaned = abs(Y_cleaned / n);  % Two-sided spectrum
P1_cleaned = P2_cleaned(1:n/2+1);  % Single-sided spectrum
P1_cleaned(2:end-1) = 2 * P1_cleaned(2:end-1);  % Scale appropriately

% Plot the cleaned power spectrum
figure;
plot(f, P1_cleaned);
title('Power Spectrum of Filtered and Notch-Cleaned Signal (4-40 Hz Bandpass, 60 Hz Notch)');
xlabel('Frequency (Hz)');
ylabel('Power');


%%

% Parameters

% Perform FFT on raw signal
Y_raw = fft(rawSignal);
P2_raw = abs(Y_raw / n);         % Two-sided spectrum
P1_raw = P2_raw(1:n/2+1);        % Single-sided spectrum
P1_raw(2:end-1) = 2 * P1_raw(2:end-1);  % Scale appropriately

% Perform FFT on filtered signal
Y_filtered = fft(cleanedSignal1);
P2_filtered = abs(Y_filtered / n);         % Two-sided spectrum
P1_filtered = P2_filtered(1:n/2+1);        % Single-sided spectrum
P1_filtered(2:end-1) = 2 * P1_filtered(2:end-1);  % Scale appropriately

% Frequency axis
f = samplingRate * (0:(n/2)) / n;

% Plot power spectrum of raw and filtered signals
figure;
subplot(3, 1, 1);
plot(f, P1_raw);
title('Power Spectrum of Raw Signal');
xlabel('Frequency (Hz)');
ylabel('Power');

subplot(3, 1, 2);
plot(f, P1_filtered);
title('Power Spectrum of Filtered Signal (4-40 Hz Bandpass, 50 Hz Notch)');
xlabel('Frequency (Hz)');
ylabel('Power');

subplot(3,1,3)
plot(f, P1_cleaned);
title('Power Spectrum of Filtered and Notch-Cleaned Signal (4-40 Hz Bandpass, 60 Hz Notch)');
xlabel('Frequency (Hz)');
ylabel('Power');
