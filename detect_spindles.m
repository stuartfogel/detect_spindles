function [EEG] = detect_spindles(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Detect Spindles in EEG data
%
% INPUT:    EEG = EEGLab structure
%           PARAM = structure of parameters (see below)
%
% OUTPUT:   EEG = same structure with spindle markers (EEG.event)
%
% Authors:  Stephane Sockeel, PhD, University of Montreal
%           Stuart Fogel, PhD, University of Ottawa
%           Thanks to support from Julien Doyon and input from Arnaud Bore.
%           Copyright (C) Stuart fogel & Stephane Sockeel, 2016
%           See the GNU General Public License for more details.
%
% Contact:  sfogel@uottawa.ca
%
% Date:     June 8, 2016
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

%% INPUT ARGUMENTS
if nargin < 1; EEG = []; end
if nargin < 2; PARAM.emptyparam = 1; end

%% CUSTOM PARAMETERS
if PARAM.emptyparam == 1
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
    ,'minDur', [0.49,3.01] ... minimum spindle duration. Default: [0.49 3.01].
    ,'eventName', {{'Spindle'}} ... name of event. Default: {{'Spindle'}}.
    ,'allsleepstages', {{'N1','N2','N3','R','W','unscored'}} ... name of all sleep stage markers. Default: {{'N1','N2','N3','R','W','unscored'}}.
    ,'goodsleepstages', {{'N2','N3'}} ... name of sleep stage markers to keep spindle events. Default: {{'N2','N3'}}.
    ,'badData', {{'Movement'}} ... name for movement artifact. Default: {{'Movement'}}.
    ,'save_result_file', 1 ... file type to save markers to a file. If empty [], none.
    ,'suffix', {'SpDet'} ... file suffix for output dataset. Default: {'SpDet'}.
    ,'emptyparam', 0 ... set PARAM.emptyparam to not empty.
    );
end

%% RUN PIPELINE
if length(EEG)>1 % batch mode
    for iSet = 1:length(EEG)
        EEG(iSet).setname = [EEG(iSet).setname '_' PARAM.suffix]; % update setname
        [EEG(iSet)] = DS_pipeline_detect_spindles(EEG(iSet),PARAM);
        fprintf(1,'%s\n',['Saving file ' EEG(iSet).setname '.set']);
        EEG(iSet) = pop_saveset(EEG(iSet),'filepath',EEG(iSet).filepath,'filename',EEG(iSet).setname,'savemode','onefile');
    end
else
    EEG.setname = [EEG.setname '_' PARAM.suffix]; % update setname
    [EEG] = DS_pipeline_detect_spindles(EEG,PARAM);
    eeg_checkset(EEG);
    fprintf(1,'%s\n',['Saving file ' EEG.setname '.set']);
end

end
