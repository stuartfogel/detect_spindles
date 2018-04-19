function EEG = DS_remBadMinMax(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Remove events during bad data
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

% to be sure that all is in the right order
[~, idx] = sort([Event.latency]);
Event = Event(idx);
SpindleIdx = find(ismember({Event.type},PARAM.eventName));
ToRmv = [];

for iSpin = SpindleIdx % loop on Spindle
    bad = find(ismember({Event(1:iSpin).type},PARAM.badData),1,'last');
    if ~isempty(bad)
        if Event(bad).latency + Event(bad).duration > Event(iSpin).latency
            ToRmv(end+1) = iSpin;
        end
    end
end

% let's kill the bad spindle
Event(ToRmv) = [];
EEG.event = Event;

end
