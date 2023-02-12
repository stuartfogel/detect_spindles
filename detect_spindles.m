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
% This file is part of 'detect_spindles'.
% See https://github.com/stuartfogel/detect_spindles for details.
%

% Copyright (C) Stuart Fogel & Sleep Well, 2022.
% https://socialsciences.uottawa.ca/sleep-lab/
% https://www.sleepwellpsg.com
%
% See the GNU General Public License v3.0 for more information.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above author, license,
% copyright notice, this list of conditions, and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above author, license,
% copyright notice, this list of conditions, and the following disclaimer in
% the documentation and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% 0) Start pipeline
addpath('src')
t0 = clock; % start time
fprintf(1,'%s\n',['------------------------ ' datestr(t0) ' ------------------------']);
fprintf(1,'%s\n',['Processing file ' EEG.setname]);
% Check data format for compatibility. Ensure EEG.data are double (filtfilt requirement). This also resolves other related issues.
EEG.data = double(EEG.data);

%% 1) COMPLEX DEMODULATION OR RMS
% progress bar
progress = waitbar(0, 'Performing Complex Demodulation / RMS...');
pause(1)

% 1a) channels of interest
if ~isempty(PARAM.channels_of_interest)
    EEGcoi = DS_extract_ChOI(EEG,PARAM);
end

% 1b) if complex demodulation is your preference
if PARAM.cdemodORrms == 1
    fprintf(1,'%s\n',' ');
    fprintf(1,'%s\n','STEP 1: COMPLEX DEMODULATION');
    EEGfreq = DS_complexDemodulation(EEGcoi,PARAM);
    % 1c) if RMS is your weapon of choice
elseif PARAM.cdemodORrms == 0
    fprintf(1,'%s\n',' ');
    fprintf(1,'%s\n','STEP 1: ROOT MEAN SQUARE TRANSFORMATION');
    EEGfreq = DS_rms(EEGcoi,PARAM);
else
    error('Please choose either complex demodulate or RMS to extract frequencies of interest.')
end

t1 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t1,t0)) ' sec.']);

%% 2) Z-SCORE NORMALIZATION
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 2: Z-SCORE NORMALIZATION');

% progress bar
waitbar(1/6*1,progress,'Normalizing signal...');
pause(1)

% 2a) set data during movements to NaN so they don't contaminate normalization
EEGnan = DS_NaNbadData(EEGfreq,PARAM);

% 2b) Signal normalization
EEGz = DS_Zscore_new(EEGnan,PARAM);

t2 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t2,t1)/60) ' min.']);

%% 3) SPINDLE DETECTION
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 3: SPINDLE DETECTION');

% progress bar
waitbar(1/6*2,progress,'Detecting spindles...');
pause(1)

% detect spindles
[EEGs] = DS_Threshold(EEGz,PARAM);
EEGs = eeg_checkset(EEGs,'eventconsistency');

t3 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t3,t2)/60) ' min.']);

%% 4) REMOVE SPINDLES OUTSIDE NREM
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 4: REMOVE SPINDLES OUTSIDE NREM');

% progress bar
waitbar(1/6*3,progress,'Remove spindles outside NREM...');
pause(1)

if ~isempty(PARAM.goodsleepstages)
    EEGb = DS_remBadSleepStage(EEGs, PARAM);
    EEGb = eeg_checkset(EEGb,'eventconsistency');
    t4 = clock;
else
    t4 = clock;
    disp('Removed spindles from outside NREM skipped')
end

fprintf(1,'%s\n',[' ~~ ' num2str(etime(t4,t3)/60) ' min.']);

%% 5) REMOVE SPINDLES DURING MOVEMENT ARTIFACT
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 5: REMOVE SPINDLES DURING MOVEMENT ARTIFACT');

% progress bar
waitbar(1/6*4,progress,'Remove spindles during movement...');
pause(1)

EEGm = DS_remBadMinMax(EEGb, PARAM);
EEGm = eeg_checkset(EEGm,'eventconsistency');

t5 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t5,t4)/60) ' min.']);

%% 6) SPINDLE CHARACTERIZATION
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 6: SPINDLE CHARACTERIZATION');

% progress bar
waitbar(1/6*5,progress,'Characterizing spindles...');
pause(1)

% replace original EEG dataset events with final events structure
EEG.event = EEGm.event;

EEG = DS_characSpindles(EEG, PARAM);
EEG = eeg_checkset(EEG, 'checkur');

t6 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t6,t5)/60) ' min.']);

%% 7) EXPORT SPINDLE MARKERS
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 7: EXPORT SPINDLE MARKERS');

% progress bar
waitbar(1/6*5,progress,'Export spindle results...');
pause(1)

if isfield(PARAM,'save_result_file')
    if ~isempty(PARAM.save_result_file)
        DS_export_Spindles_csv(EEG,PARAM);
    end
end

t7 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t7,t6)/60) ' min.']);

% progress bar
waitbar(1/6*6,progress,'Spindle detection complete...');
pause(1)
close(progress)

end
