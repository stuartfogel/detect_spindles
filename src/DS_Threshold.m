function [ZS, markers] = DS_Threshold(ZS,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Detect events beyond a threshold
%
% Part of detect_spindles toolbox:
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

DATA = ZS.data;
channels = ZS.chanlocs;
ZSDelay = round(PARAM.ZSDelay * ZS.srate);

% check the dimension : must be (ch x times)
if size(DATA,2)<size(DATA,1)
    DATA = DATA';
end
[nbCh, nbPts] = size(DATA);

% create marker structure based on original
markers = ZS.event;

% add necessary spindle events fields to original structure
if ~isfield(markers,'type')
    for nEvt=1:length(markers); markers(nEvt).type = []; end
end
if ~isfield(markers,'latency')
    for nEvt=1:length(markers); markers(nEvt).latency = []; end
end
if ~isfield(markers,'channel')
    for nEvt=1:length(markers); markers(nEvt).channel = []; end
end
if ~isfield(markers,'duration')
    for nEvt=1:length(markers); markers(nEvt).duration = []; end
end
if ~isfield(markers,'peak')
    for nEvt=1:length(markers); markers(nEvt).peak = []; end
end
if ~isfield(markers,'amplitude')
    for nEvt=1:length(markers); markers(nEvt).amplitude = []; end
end
if ~isfield(markers,'area')
    for nEvt=1:length(markers); markers(nEvt).area = []; end
end
if ~isfield(markers,'frequency')
    for nEvt=1:length(markers); markers(nEvt).frequency = []; end
end
if ~isfield(markers,'urevent')
    for nEvt=1:length(markers); markers(nEvt).urevent = []; end
end

% for iCh = 1:nbCh
for iCh = 1:nbCh
    t = 1;
    CONTINUE = 1;
    while CONTINUE
        % loop over time
        t;
        new_detection = find(DATA(iCh,t:end)>PARAM.ZSThreshold,1);
        if isempty(new_detection)
            CONTINUE = 0;
        else
            new_detection = t-1+new_detection; % il faut enlever 1 car 't' correspond au premier terme de la matrice
            begin_time = find(DATA(iCh,1:new_detection)<PARAM.ZSBeginThreshold,1,'last')+1;
            end_time = find(DATA(iCh,new_detection:end)<PARAM.ZSResetThreshold,1) + new_detection-1;
            if isempty(begin_time)
                begin_time = 1;
            end
            if isempty(end_time)
                end_time = nbPts;
            end
            [max_ampli, peak_time] = max(DATA(iCh,new_detection:end_time));
            peak_time = peak_time +new_detection-1;
            % create marker structure with updated fields
            newMrks = markers([]);
            % populate event information
            newMrks(1).type = PARAM.eventName;
            newMrks(1).latency = begin_time;
            newMrks(1).channel = channels(iCh).labels;
            newMrks(1).duration = end_time - begin_time;
            newMrks(1).peak = peak_time;
            newMrks(1).amplitude = [];
            newMrks(1).area = [];
            newMrks(1).frequency = [];
            newMrks(1).urevent = [];
            % Apply minimum spindle duration criteria, if specified in PARAM.minDur
            if ~isempty(PARAM.minDur)
                if newMrks.duration > PARAM.minDur*ZS.srate && newMrks.duration < PARAM.maxDur*ZS.srate
                    markers = [markers newMrks];
                end
            else
                markers = [markers newMrks];
            end
            % if we come back in a spindle => go to the next point below the threshold
            t = (end_time + ZSDelay) + find(DATA(iCh,(end_time +1 + ZSDelay):end)<PARAM.ZSThreshold,1);
            if isempty(t)
                CONTINUE = 0;
            end
        end
    end
end
ZS.event = markers;

end
