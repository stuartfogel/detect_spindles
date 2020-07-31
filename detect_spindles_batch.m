function [ALLEEG] = detect_spindles_batch()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Build EEG structure from multiple EEG datasets to batch run detect_spindles
%
% Contact:  sfogel@uottawa.ca
%
% Date:     May 6, 2020
%
% Citation: Ray, L.B., Sockeel, S., Soon, M., Bore, A., Myhr, A.,
%           Stojanoski, B., Cusack, R., Owen, A.M., Doyon, J., Fogel, S.,
%           2015. Expert and crowd-sourced validation of an individualized
%           sleep spindle detection method employing complex demodulation
%           and individualized normalization. Front. Hum. Neurosci. 9.
%           doi:10.3389/fnhum.2015.00507
%
%           journal.frontiersin.org/article/10.3389/fnhum.2015.00507/full
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% LOAD EEGLAB
if ~isempty(which('eeglab'))
    eeglab;
else
    error('Add top folder for eeglab to the path')
end

%% CUSTOM PARAMETERS

PARAM = struct(...
    'cdemodORrms',1 ... use complex demodulation [1], or root mean square [0] to extract frequency of interest. Default: [1].
    ,'PB_forder',1 ... order for the first low pass filter. Default [1].
    ,'cdemod_freq', 13.5 ...    central frequency (i.e. Carrier frequency in Hz) for the complex demodulation. Default: [13.5].
    ,'cdemod_filter_lowpass', 5 ... bandwidth about central frequency in CD. Default: [5].
    ,'cdemod_forder', 4 ...    filter order for the complex demodulation. Default: [4].
    ,'rmshp', 11 ... high pass filter if using rms. Default: [11].
    ,'rmslp', 16 ... low pass filter if using rms. Default: [16].
    ,'channels_of_interest',{{'Fz','Cz','Pz'}} ... selected channels. Default: {{'Fz','Cz','Pz'}}
    ,'ZSwindowlength', 60 ... window for ZSCORE (in seconds). Default: [60].
    ,'ZSThreshold', 2.33 ... Threshold for the ZScore. Default: [2.33].
    ,'ZSResetThreshold', 0.1 ... Value for the reset. Default: [0.1-0.25].
    ,'ZSBeginThreshold', 0.1 ... Value to detect the begining of spindles. Default: [0.1-0.25].
    ,'ZSDelay', 0.25 ... minimum delay btw 2 spindles on the same channel (sec.). Default: [0.25].
    ,'minDur', 0.49 ... minimum spindle duration. Default: [0.49] (in order to include 0.5 sec spindles).
    ,'eventName', {{'Spindle'}} ... name of event. Default: {{'Spindle'}}.
    ,'allsleepstages', {{'N1','N2','N3','R','W','unscored'}} ... name of all sleep stage markers. Default: {{'N1','N2','N3','R','W','unscored'}}.
    ,'goodsleepstages', {{'N2','N3'}} ... name of sleep stage markers to keep spindle events. Default: {{'N2','N3'}}.
    ,'badData', {{'Movement'}} ... name for movement artifact. Default: {{'Movement'}}.
    ,'save_result_file', 1 ... file type to save markers to a file. If empty [], none.
    ,'suffix', {'SpDet'} ... file suffix for output dataset. Default: {'SpDet'}.
    ,'emptyparam', 0 ... set PARAM.emptyparam to not empty.
    );

%% SPECIFY FILENAMES (OPTIONAL)

% you can manually specify filenames here, or leave empty for pop-up
pathname = '';
filename = {'',...
    ''
    };

%% MANUALLY SELECT *.SET FILES

if isempty(pathname)
    [filename, pathname] = uigetfile2( ...
        {'*.set','EEGlab Dataset (*.set)'; ...
        '*.mat','MAT-files (*.mat)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'multiselect', 'on');
end

% check the filename(s)
if isequal(filename,0) || isequal(pathname,0) % no files were selected
    disp('User selected Cancel')
    return;
else
    if ischar(filename) % Only one file was selected. That's odd. Why would you use this script?
        error('Only one dataset selected. Batch mode is for multiple datasets.')
    end
end

%% BUILD EEG BATCH AND LAUNCH SPINDLE DETECTION
for nfile = 1:length(filename)
    EEG = pop_loadset('filename',filename{1,nfile},'filepath',pathname);
    ALLEEG(nfile) = EEG;
end

ALLEEG = detect_spindles(ALLEEG,PARAM);

end