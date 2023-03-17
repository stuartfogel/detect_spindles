function EEG = detect_spindles(EEG,PARAM)

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
EEG.data = double(EEG.data); % required for filtering
% extract EEG periods of interest based on sleep stage labels
EEGperiods = DS_getEEGperiods(EEG,PARAM);

%% 1) COMPLEX DEMODULATION OR RMS
% progress bar
progress = waitbar(1/5*0, 'Performing Complex Demodulation / RMS...');
pause(1)

% 1a) channels of interest
if ~isempty(PARAM.channels_of_interest)
    EEGcoi = DS_extract_ChOI(EEG,PARAM);
else
    EEGcoi = EEG;
end
EEGfreq = EEGcoi;

% 1b) if complex demodulation is your preference
if PARAM.cdemodORrms == 1
    EEGfreq = DS_complexDemodulation(EEGfreq,PARAM);
% 1c) if RMS is your weapon of choice
elseif PARAM.cdemodORrms == 0
    % filer
    EEGfreq = pop_eegfiltnew(EEGfreq, 'locutoff',PARAM.rmshp,'hicutoff',PARAM.rmslp);
    EEGfreq = DS_rms(EEGfreq,PARAM);
else
    error('Please choose either complex demodulate or RMS to extract frequencies of interest.')
end

t1 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t1,t0)) ' sec.']);

%% 2) Z-SCORE NORMALIZATION

% progress bar
waitbar(1/5*1,progress,'Normalizing signal...');
pause(1)

% 2a) set data during movements to NaN so they don't contaminate normalization
EEGnan = DS_NaNbadData(EEGfreq,PARAM);
EEGz = EEGnan;

% 2b) Signal normalization
for nPer = 1:height(EEGperiods)
    StartEEG = EEGperiods{nPer,'StartEEG'}{:};
    EndEEG = EEGperiods{nPer,'EndEEG'}{:};
    EEGz = DS_Zscore(EEGz,StartEEG,EndEEG,PARAM);
end
clear nPer StartEEG EndEEG

t2 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t2,t1)) ' sec.']);

%% 3) SPINDLE DETECTION

% progress bar
waitbar(1/5*2,progress,'Detecting spindles...');
pause(1)

% detect spindles
EEGs = DS_Threshold(EEGz,PARAM);
EEGs = eeg_checkset(EEGs,'eventconsistency');

t3 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t3,t2)) ' sec.']);

%% 5) SPINDLE CHARACTERIZATION

% progress bar
waitbar(1/5*3,progress,'Characterizing spindles...');
pause(1)

% replace original EEG dataset events with final events structure
EEG.event = EEGs.event;

% get additional spindle characteristics from raw EEG trace
EEG = DS_characSpindles(EEG, PARAM);
EEG = eeg_checkset(EEG, 'checkur');

t4 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t4,t3)) ' sec.']);

%% 6) EXPORT SPINDLE MARKERS

% progress bar
waitbar(1/5*4,progress,'Export spindle results...');
pause(1)

if isfield(PARAM,'save_result_file')
    if ~isempty(PARAM.save_result_file)
        EEGtemp = pop_selectevent(EEG,'type',PARAM.eventName,'select','normal','deleteevents','on');
        if ~isempty(EEG.event)
            results = struct2table(EEGtemp.event);
            writetable(results, [EEG.filepath EEG.setname '_events.csv']);
            save([EEG.filepath EEG.setname '_events'],'results');
        else
            warning('No spindles detected.')
        end
    end
end

t5 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t5,t4)) ' sec.']);

% progress bar
waitbar(1/5*5,progress,'Spindle detection complete...');
pause(1)
close(progress)

end
