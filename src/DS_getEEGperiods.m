function [EEGperiods] = DS_getEEGperiods(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Extract EEG periods of a certain sleep stage label
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
% Date:     March 16, 2023
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

% Copyright (C) Stuart Fogel & Sleep Well, 2023.
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

%% setup variables
Name = [];
EEGperiod = [];
StartEEG = [];
EndEEG = [];
evtCount = 1;

% convert eeglab event structure to table
events = struct2table(EEG.event);

% filter events table so that it only contains sleep stages
events(~ismember(events.type,PARAM.allsleepstages),:) = [];

%% find start and end of EEG periods
for nStage = 1:length(PARAM.goodsleepstages)
    for nEvt = 1:height(events)
        if strcmp(char(table2cell(events(nEvt,'type'))),PARAM.goodsleepstages(nStage))
            if nEvt == height(events) % catch if last epoch is valid
                if ~strcmp(table2cell(events(nEvt-1,'type')),PARAM.goodsleepstages(nStage)) % capture isolated and last epoch
                    Name{evtCount} = EEG.setname;
                    EEGperiod{evtCount} = PARAM.goodsleepstages{nStage};
                    StartEEG{evtCount} = round(table2array(events(nEvt,'latency')));
                    EndEEG{evtCount} = round(table2array(events(nEvt,'latency'))) + table2array(events(nEvt,'duration')) - 1;
                    evtCount = evtCount + 1;
                elseif strcmp(char(table2cell(events(nEvt,'type'))),PARAM.goodsleepstages(nStage)) % if last event is not isolated, but still valid
                    EndEEG{evtCount} = round(table2array(events(nEvt,'latency'))) + table2array(events(nEvt,'duration')) - 1;
                    evtCount = evtCount + 1;
                else
                    continue
                end
            else
                if ~strcmp(char(table2cell(events(nEvt-1,'type'))),PARAM.goodsleepstages(nStage)) && ~strcmp(char(table2cell(events(nEvt+1,'type'))),PARAM.goodsleepstages(nStage)) % capture isolated periods
                    Name{evtCount} = EEG.setname;
                    EEGperiod{evtCount} = PARAM.goodsleepstages{nStage};
                    StartEEG{evtCount} = round(table2array(events(nEvt,'latency')));
                    EndEEG{evtCount} = round(table2array(events(nEvt+1,'latency'))) + table2array(events(nEvt,'duration')) - 1;
                    evtCount = evtCount + 1;
                elseif ~strcmp(char(table2cell(events(nEvt-1,'type'))),PARAM.goodsleepstages(nStage)) && strcmp(char(table2cell(events(nEvt+1,'type'))),PARAM.goodsleepstages(nStage)) % capture start of >1 periods
                    Name{evtCount} = EEG.setname;
                    EEGperiod{evtCount} = PARAM.goodsleepstages{nStage};
                    StartEEG{evtCount} = round(table2array(events(nEvt,'latency')));
                elseif ~strcmp(char(table2cell(events(nEvt+1,'type'))),PARAM.goodsleepstages(nStage)) % capture the end of the period
                    EndEEG{evtCount} = round(table2array(events(nEvt+1,'latency'))) + table2array(events(nEvt,'duration')) - 1;
                    evtCount = evtCount + 1;
                else
                    continue
                end
            end
        end
    end
end

% put it in a table for output
EEGperiods = table(Name(:),EEGperiod(:),StartEEG(:),EndEEG(:),'VariableNames',{'Name','EEGperiod','StartEEG','EndEEG'});
EEGperiods = sortrows(EEGperiods,"StartEEG");
clear EndEEG StartEEG evtCount EEGper EEGperiod Name events nEvt

end