function [EEG, marker] = detect_spindles(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Detect Spindles in EEG data
%
% INPUT:    EEG = EEGLab structure
%           PARAM = structure of parameters (see below)
%
% OUTPUT:   EEG = same structure with spindle markers (EEG.event)
%           marker = spindle markers
%
% Authors:  Stephane Sockeel, PhD, University of Montreal
%           Stuart Fogel, PhD, Western University
%           Thanks to support from Julien Doyon and input from Arnaud Bore.
%           Copyright (C) Stuart fogel & Stephane Sockeel, 2016
%           See the GNU General Public License for more details.
%
% Contact:  sfogel@uwo.ca
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

%% basic options
% for dependencies
addpath('./src')
addpath(genpath('./eeglab13_2_2b'))
% input arguments
if nargin < 1; EEG = []; end
if nargin < 2; PARAM.emptyparam = 1; end

%% Specify Filename(s)
% you can manually specify filenames here, or leave empty for pop-up
pathname = '';
filename = {'',...
    ''
    };

%% Open interface to select *.mat file(s)
if isempty(pathname)
    if isempty(EEG)
        [filename,pathname] = uigetfile2(   {'*.mat', 'eeglab mat file (*.MAT)'; ...
            '*.set', 'EEGlab Dataset (*.SET)'; ...
            '*.*', 'All Files (*.*)'}, ...
            'Choose files to process', ...
            'Multiselect', 'on');
        
    end
end

% check the filename(s)
if isequal(filename,0) % no files were selected
    disp('User selected Cancel')
    return;
else
    if ischar(filename) % only one file was selected
        filename = cellstr(filename); % put the filename in the same cell structure as multiselect
    end
end

%% Output directory
% Specify output directory, or leave empty to use pop-up
resultDir = '';

if isempty(resultDir)
    disp('Please select a directory in which to save the results.');
    resultDir = uigetdir('', 'Select the directory in which to save the results');
end

tic

for nfile = 1:length(filename)
    
    %% Load EEG files
    
    [path,name,ext] = fileparts(char(strcat(pathname, filename(nfile))));
    
    if strfind(ext,'.vhdr')
        % import Brain Broducts to eeglab
        EEG = pop_loadbv(pathname,char(filename(nfile)));
    elseif strfind(ext,'.mat')
        % load mat
        EEG = pop_loadset('filename',filename{1,nfile},'filepath',pathname);
    elseif strfind(ext,'.set')
        % load eeglab
        EEG = pop_loadset('filename',filename{1,nfile},'filepath',pathname);
    else
        error('Unknown file type!')
    end
    
    % display file loaded
    disp(strcat('File ',{' '},filename{1,nfile},{' '},'loaded'))
    
    % fill important file info
    EEG.setname = char(strcat(name,'_spDet'));
    EEG.filename = char(strcat(EEG.setname,'.set'));
    EEG.filepath = [resultDir,filesep];
    OutputPath = [resultDir,filesep];
    OutputFile = EEG.setname;
    
    %% CUSTOM PARAMETERS
    if PARAM.emptyparam == 1
        PARAM = struct(...
            'PB_forder',1 ... order for the first low pass filter. Default [1].
            ,'cdemod_freq', 13.5 ...    central frequency (i.e. Carrier frequency in Hz) for the complex demodulation. Default: [13.5].
            ,'cdemod_filter_lowpass', 5 ... cutoff frequency for the low pass filter in CD. Default: [5].
            ,'cdemod_forder', 4 ...    filter order for the complex demodulation. Default: [4].
            ,'channels_of_interest',{{'Fz','Cz','Pz'}} ... selected channels. Default: {{'Fz','Cz','Pz'}}
            ,'ZSwindowlength', 60 ... window for ZSCORE (in seconds). Default: [60].
            ,'ZSThreshold', 2.33 ... Threshold for the ZScore. Default: [2.33].
            ,'ZSResetThreshold', 0.25 ... Value for the reset. Default: [0.25].
            ,'ZSBeginThreshold', 0.25 ... Value to detect the begining of spindles. Default: [0.25].
            ,'ZSDelay', 0.25 ... minimum delay btw 2 spindles on the same channel (sec.). Default: [0.25].
            ,'minDur', 0.25 ... minimum spindle duration. Default: [0.25].
            ,'eventName', {{'Spindle'}} ... name of event. Default: {{'Spindle'}}.
            ,'allsleepstages', {{'N1','N2','N3','N4','REM','W','unscored'}} ... name of all sleep stage markers. Default: {{'N1','N2','N3','N4','REM','W','unscored'}}.
            ,'goodsleepstages', {{'N2','N3','N4'}} ... name of sleep stage markers to keep spindle events. Default: {{'N2','N3','N4'}}.
            ,'badData', {{'Movement'}} ... name for movement artifact. Default: {{'Movement'}}.
            ,'save_result_file','.csv' ... file type to save markers to a file. If empty []: popup window. Default: {{'.csv'}}
            ,'save_mat_file', 1 ... set to = 1 to save EEG, markers and PARAM to a .mat file. If empty []: popup window. Default: [1].
            ,'output_allfiles', 0 ... set at 1 if you want the complete results with all steps. Note EEG struct will be different dimentions. Default: [0].
            );
    end
    
    %% real pipeline
    if length(EEG)>1
        marker = cell(1,length(EEG));
        for iRun = 1:length(EEG)
            [EEG(iRun), marker{iRun}, PARAM] = DS_pipeline_detect_spindles(EEG(iRun),PARAM,OutputFile(iRun),OutputPath(iRun));
        end
    else
        [EEG, marker, PARAM] = DS_pipeline_detect_spindles(EEG,PARAM,OutputFile,OutputPath);
        eeg_checkset(EEG);
    end
    
    %% saving results
    if isfield(PARAM,'save_mat_file')
        if isempty(PARAM.save_result_file)
            [OutputFile, OutputPath] = uiputfile('*.mat','Export results ?');
        elseif ~isempty(PARAM.save_result_file)
            save([OutputPath, OutputFile],'EEG','marker','PARAM');
        end
    end
    disp(strcat('File ',{' '},EEG.setname,{' '},'completed!'))
    clearvars -except EEG PARAM filename pathname resultDir
end

disp('SPINDLE DETECTION COMPLETE!')
toc

end
