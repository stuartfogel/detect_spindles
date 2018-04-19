function EEG = DS_remBadSleepStage(EEG, PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Remove events outside sleep stages of interest
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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Event = EEG.event;

if nargin<2
    PARAM = [];
end

mrkScoring = PARAM.allsleepstages;
mrkSelectedScoring = PARAM.goodsleepstages;

% to be sure that all is in the right order
[~, idx] = sort([Event.latency]);
Event = Event(idx);
for i = 1:length(Event)
    Event(i).SleepStage = ''; % initialization
end

SpindleIdx = find(ismember({Event.type},PARAM.eventName));

for iSpin = SpindleIdx % loop on Spindle
    lastScoring = find(ismember({Event(1:iSpin).type},mrkScoring),1,'last');
    if ~isempty(lastScoring)
        Event(iSpin).SleepStage = Event(lastScoring).type;
    else
        Event(iSpin).SleepStage = '';
    end
end

% let's kill the bad spindle
SpindleIdx = logical(ismember({Event.type},PARAM.eventName));
GoodScoring = logical(ismember({Event.SleepStage},mrkSelectedScoring));
% GoodScoring = logical(ismember({Event.SleepStage},deblank(mrkSelectedScoring))); % some import utilities add a trailing space to the marker names, using deblank to ignore them

Event(SpindleIdx & (~GoodScoring)) = [];
EEG.event = Event;

end
