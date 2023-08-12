%% Setup
% add relevant paths
% genpath(PATH) also adds subfolders
addpath(genpath('/Users/florian/Documents/Studium/Master/Semester 1/EEG in VR/EEG and Matlab'));

% start eeglab to import plugins
%eeglab;

%% Load data
% import eeg file
pathname = '/Users/florian/Documents/Studium/Master/Semester 1/EEG in VR/EEG and Matlab/ExerciseThursday/EEGData';
filename = 'EEG_AAT_SUB035.cnt';

%% Pre-processing
EEG = pop_loadeep_v4(fullfile(pathname,filename), 'triggerfile', 'on');
EEG = pop_resample(EEG, 128); % down-sample data

% reduce muscle noise (low-pass filtering) and gradual skin potentials (high-pass filtering)
EEG = pop_eegfiltnew(EEG, 1, []); % high-pass
EEG = pop_eegfiltnew(EEG, [], 30); % low-pass

% remove noisy channels
EEG = pop_select(EEG, 'nochannel', {'BIP1' 'BIP2' 'BIP3' 'BIP4' 'AUX1' 'AUX2' 'AUX3' 'AUX4' 'CP3'});
EEG = pop_chanedit(EEG, 'lookup', '/Users/florian/Documents/Studium/Master/Semester 1/EEG in VR/EEG and Matlab/ExerciseThursday/standard_BESA/standard-10-5-cap385.elp'); % localize channels

% data cleaning (uncomment command below to manually reject noise)
%eegplot(EEG.data, 'command', 'rej=TMPREJ', 'srate', EEG.srate, 'eloc_file', EEG.chanlocs, 'events', EEG.event)
temprej = eegplot2event(rej,-1);
EEG = eeg_eegrej(EEG, temprej(:,[3 4]));

%% ICA
%runamica15(EEG.data);
mod = loadmodout15('/Users/florian/Documents/Studium/Master/Semester 1/EEG in VR/EEG and Matlab/ExerciseThursday/amica');
EEG.icasphere = mod.S;
EEG.icaweights = mod.W;
eeg_checkset();

% epoching & baseline correction
window = [-0.5 3]; % cut half a second before trigger event and 3s after trigger
% trigger event labels at which to epoch
epoch_trigg = {'41', '42', '43', '44', '45', '46', '47', '48', '49', '50', '51', '52', '53', '54', '55', '56', '57', '58', '59', '60', '61', '62', '63', '64', '65', '66', '67', '68', '69', '70', '71', '72', '73', '74', '75', '76', '77', '78', '79', '80', '81', '82', '83', '84', '85', '86', '87', '88', '89', '90', '91', '92', '93', '94', '95', '96', '97', '98', '99', '100', '101', '102', '103', '104', '105', '106', '107', '108', '109', '110', '111', '112', '113', '114', '115', '116', '117', '118', '119', '120', '121', '122', '123', '124', '125', '126', '127', '128'};
EEG = pop_epoch(EEG, epoch_trigg, window, 'epochinfo', 'yes'); % epoching
EEG = pop_rmbase(EEG, [-100 0]); % baseline correction: use 100ms before trigger event to calculate baseline and subtract

% https://labeling.ucsd.edu/tutorial/labels
EEG = iclabel(EEG);
pop_selectcomps(EEG);
pop_viewprops(EEG, 0); % open IC label

comps_to_rej = find(EEG.reject.gcompreject);
EEG = pop_subcomp(EEG, comps_to_rej, 0);

%% Plotting
% Plot the data
%eegplot(EEG.data, 'srate', EEG.srate, 'eloc_file', EEG.chanlocs, 'events', EEG.event)

% Plot ERP for congruent (triggers 41-84) and incongruent (85-128) trials
% split data (first half of all trials is congruent), average over trials, select channel (20)
congruent = EEG.data(20, :, 1:end/2);
incongruent = EEG.data(20, :, (end/2)+1:end);
congruent_ERP = mean(congruent, 3);
incongruent_ERP = mean(incongruent, 3);
x = EEG.times;
% plot ERP
plot(x, congruent_ERP, x, incongruent_ERP, '--', 'LineWidth', 2);
xline(0, 'g', {'Trial','onset'});
title('ERPs per condition for channel 20, subject 35')
xlabel('Latency (ms)')
ylabel('Potential (\muV)')
legend({'congruent','incongruent'},'Location','southeast')