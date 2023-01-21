function [EEG,com] = pop_detect_spindles(EEG)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Detect Spindles in EEG data
%
% INPUT:    EEG = EEGLab structure
%           PARAM = structure of parameters (see below)
%
% OUTPUT:   EEG = same structure with spindle markers (EEG.event)
%           marker = spindle markers
%           PARAM = user-defined parameters
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
% See https://github.com/stuartfogel/detect_REMS for details.
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

% handle history
com = '';
if nargin < 1
    help pop_detect_spindles;
    return;
end

% GUI geometry setup
g = [3, 2];
geometry = {1,g,g,g,g,g,1,g,g,1,g,g,1,g,g,g,g,g,1,1,1 [2 2 1]};
geomvert = [1 1 1 1 1 1 2 1 1 2 1 1 2 1 1 1 1 1 2 1 1 1];

% select channels
cb_chan = 'pop_chansel(get(gcbf, ''userdata''), ''field'', ''labels'', ''handle'', findobj(''parent'', gcbf, ''tag'', ''channels''));';

% build GIU
uilist = { ...
    ... label settings
    {'style', 'text', 'string', 'Event Labels'} ...
    {'style', 'text', 'string', 'Label for spindle event'} ...
    {'style', 'edit', 'string', 'Spindle' 'tag' 'eventName'} ...
    {'style', 'text', 'string', 'All sleep stage labels'} ...
    {'style', 'edit', 'string', 'W N1 N2 SWS REM Unscored' 'tag' 'allsleepstages'} ...
    {'style', 'text', 'string', 'Sleep stages to detect spindles'} ...
    {'style', 'edit', 'string', 'N2 SWS' 'tag' 'goodsleepstages'} ...
    {'style', 'text', 'string', 'Movement artifact label'} ...
    {'style', 'edit', 'string', 'Movement' 'tag' 'badData'} ...
    {'style', 'text', 'string', 'File suffix for new dataset'} ...
    {'style', 'edit', 'string', 'SpDet' 'tag' 'suffix'} ...
    ... complex demodulation settings
    {'style', 'text', 'string', 'Complex demodulation (CD) settings'} ...
    {'style', 'text', 'string', 'Central frequency for CD'} ...
    {'style', 'edit', 'string', '13.5' 'tag' 'cdemod_freq'} ...
    {'style', 'text', 'string', 'Bandwidth about CD central frequency'} ...
    { 'Style', 'edit', 'string', '5' 'tag' 'cdemod_filter_lowpass' } ...
    ... root mean quare settings
    {'style', 'text', 'string', 'Root mean square (RMS) settings'} ...
    {'style', 'text', 'string', 'High pass filter for RMS (optiona)'} ...
    { 'Style', 'edit', 'string', '11' 'tag' 'rmshp' } ...
    {'style', 'text', 'string', 'Low pass filter for RMS (optional)'} ...
    { 'Style', 'edit', 'string', '16' 'tag' 'rmslp' } ...
    ...z-score normalization and detection settings
    {'style', 'text', 'string', 'Z-Score normalization and detection settings'} ...
    {'style', 'text', 'string', 'Z-Score event detection threshold'} ...
    { 'Style', 'edit', 'string', '2.33' 'tag' 'ZSThreshold' } ...
    {'style', 'text', 'string', 'Normalization sliding window length (sec)'} ...
    { 'Style', 'edit', 'string', '60' 'tag' 'ZSwindowlength' } ...
    {'style', 'text', 'string', 'Minimum duration (sec) between spindle events'} ...
    { 'Style', 'edit', 'string', '0.25' 'tag' 'ZSDelay' } ...
    {'style', 'text', 'string', 'Minimum spindle event duration (sec)'} ...
    { 'Style', 'edit', 'string', '0.49' 'tag' 'minDur' } ...
    {'style', 'text', 'string', 'Maximum spindle event duration (sec)'} ...
    { 'Style', 'edit', 'string', '3.01' 'tag' 'maxDur' } ...
    ... Other options
    {'style', 'text', 'string', 'Other options'} ...
    {'style', 'checkbox', 'string', 'Use CD (checked) or RMS (unchecked)', 'value', 1} ...
    ... channel options
    { 'style' 'text'       'string' '' } ...
    { 'style' 'text'       'string' 'OR channel labels or indices' } ...
    { 'style' 'edit'       'string' 'Fz Cz Pz' 'tag' 'channels' }  ...
    { 'style' 'pushbutton' 'string' '...' 'callback' cb_chan }
    };

% channel labels
if ~isempty(EEG(1).chanlocs)
    tmpchanlocs = EEG(1).chanlocs;
else
    tmpchanlocs = [];
    for index = 1:EEG(1).nbchan
        tmpchanlocs(index).labels = int2str(index);
        tmpchanlocs(index).type = '';
    end
end

% launch gui
result = inputgui('geometry', geometry, 'geomvert', geomvert, 'uilist', uilist, 'title', 'Detect Spindles -- detect_spindles()', 'helpcom', 'pophelp(''detect_spindles'')', 'userdata', tmpchanlocs);

% launch spindle detection
if ~isempty(result)
    % Set user-defined parameters
    PARAM = struct(...
        'eventName', result{1} ...
        ,'allsleepstages', {strsplit(result{2})} ...
        ,'goodsleepstages', {strsplit(result{3})} ...
        ,'badData', result{4} ...
        ,'suffix', result{5} ...
        ,'cdemod_freq', str2double(result{6}) ...
        ,'cdemod_filter_lowpass', str2double(result{7}) ...
        ,'rmshp', str2double(result{8}) ...
        ,'rmslp', str2double(result{9}) ...
        ,'ZSThreshold', str2double(result{10}) ...
        ,'ZSwindowlength', str2double(result{11}) ...
        ,'ZSDelay', str2double(result{12}) ...
        ,'minDur', str2double(result{13}) ...
        ,'maxDur', str2double(result{14}) ...
        ,'cdemodORrms', result{15} ...
        ,'channels_of_interest', {strsplit(result{16})} ...
        ... defaults
        ,'PB_forder', 1 ... order for the first low pass filter. Default: [1].
        ,'cdemod_forder', 4 ... filter order for the complex demodulation. Default: [4].
        ,'ZSBeginThreshold', 0.1 ... Value to detect the begining of spindles. Default: [0.1-0.25].
        ,'ZSResetThreshold', 0.1 ... Value for the reset. Default: [0.1-0.25].
        ,'save_result_file', 1 ... file type to save markers to a file. If empty [], none. Default: [1].
        ,'emptyparam', 0 ... set PARAM.emptyparam to not empty.
        );
    % launch pipeline
    if length(EEG)>1 % batch mode
        for iSet = 1:length(EEG)
            EEG(iSet).setname = [EEG(iSet).setname '_' PARAM.suffix]; % update setname
            [EEG(iSet)] = detect_spindles(EEG(iSet),PARAM);
            fprintf(1,'%s\n',['Saving file ' EEG(iSet).setname '.set']);
            EEG(iSet) = pop_saveset(EEG(iSet),'filepath',EEG(iSet).filepath,'filename',EEG(iSet).setname,'savemode','onefile');
        end
    else
        EEG.setname = [EEG.setname '_' PARAM.suffix]; % update setname
        EEG = detect_spindles(EEG,PARAM);
        EEG = eeg_checkset(EEG);
        fprintf(1,'%s\n',['Saving file ' EEG.setname '.set']);
    end
else
    com = '';
    return
end

com = sprintf('pop_detect_spindles(%s,%s);', inputname(1),'PARAM');
EEG = eegh(com, EEG); % update history

end