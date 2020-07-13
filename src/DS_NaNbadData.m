function EEG = DS_NaNbadData(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% NaN data during bad data events
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
badIdx = find(ismember({Event.type},PARAM.badData));

if ~isempty(badIdx)
    for ibad = badIdx % loop on bad data event
        EEG.data(:,Event(ibad).latency:Event(ibad).latency+Event(ibad).duration-1) = NaN;
    end
else
    warning('No bad data markers in your recording. You should be sure to movement artifact your data before spindle detection.')
end
clear Event badIdx ibad
end