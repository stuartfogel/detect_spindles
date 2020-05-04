function [EEG,com] = me_eeglabel(EEG,regions)
% me_eeglabel() - labels portions of continuous data in an EEGLAB dataset
%
% Usage:
%   >> EEGOUT = me_eeglabel(EEGIN, regions)
%
% Inputs:
%   INEEG      - input dataset
%   regions    - array of regions to suppress. number x [beg end]  of
%                regions. 'beg' and 'end' are expressed in term of points
%                in the input dataset. Size of the array is
%                number x 2 of regions.
%
% Outputs:
%   INEEG      - output dataset with updated data, events latencies and
%                additional events.
%
% See also:
%   POP_EEGLABEL, EEGPLUGIN_MARKEVENTS, EEGLAB
%
% Author: German Gomez-Herrero <german.gomezherrero@tut.fi>
%         Institute of Signal Processing
%         Tampere University of Technology, 2008
%
% Copyright (C) <2007>  German Gomez-Herrero, http://germangh.com%
%
% Modifed by Stuart Fogel to work with newer eeglab versions
% Brain & Mind Institute, Western University, Canada
% July 7, 2014

if nargin < 2,
    % help me_eeglabel;
    com = [];
    return;
end
if isempty(regions),
    com = [];
    return;
end

% open a window to get the label value
% --------------------------------------
uigeom = {1 1};
uilist = {{'style' 'text' 'string' 'Label for the EEG event(s):'} ...
    {'style' 'edit' 'string' ''}};
guititle = 'Choose a label - eeglabel()';
result = inputgui( uigeom, uilist, 'pophelp(''eeglabel'')', guititle, [], 'normal');

if ~isempty(result)
    label = eval(['''' result{1} '''']);
end

% handle regions from eegplot and insert labels
% -------------------------------------
if ~isempty(result)
    if size(regions,2) > 2,
        regions = regions(:,3:4);
    end
    for i = 1:size(regions,1),
        latency = (regions(i,1))/EEG.srate;
        duration = (regions(i,2)-regions(i,1))/EEG.srate;
        EEG = pop_editeventvals(EEG,'insert',{1 [] [] [] []},'changefield',{1 'latency' latency},'changefield',{1 'duration' duration},'changefield',{1 'type' label});
    end
elseif isempty(result)
    % continue
end
    
EEG = eeg_checkset(EEG,'eventconsistency');

com = sprintf('%s = me_eeglabel( %s, %s);', inputname(1), inputname(1), vararg2str({ regions }));
return;
