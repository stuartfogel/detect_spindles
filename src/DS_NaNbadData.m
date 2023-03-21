function EEG = DS_NaNbadData(EEG,PARAM,EEGperiods)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% NaN data during bad data events and stages outside NREM
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

% NaN outside good stages
for nPer = 1:height(EEGperiods)
    if nPer == 1 % NaN from start of file to first good period
        StartEEG = 1; % start of dataset
        EndEEG = EEGperiods{nPer,'StartEEG'} - 1;
        EEG.data(:, StartEEG:EndEEG) = NaN; % convert to integer to avoid unnecessary matlab warning
        StartEEG = EEGperiods{nPer,'EndEEG'} + 1;
        EndEEG = EEGperiods{nPer+1,'StartEEG'} - 1;
        EEG.data(:, StartEEG:EndEEG) = NaN; % convert to integer to avoid unnecessary matlab warning
    elseif nPer == height(EEGperiods) % NaN from end of last good period to end of files
        StartEEG = EEGperiods{nPer,'EndEEG'} + 1;
        EndEEG = EEG.pnts; % end of dataset
        EEG.data(:, StartEEG:EndEEG) = NaN; % convert to integer to avoid unnecessary matlab warning
    else % NaN in between good periods
        StartEEG = EEGperiods{nPer,'EndEEG'} + 1;
        EndEEG = EEGperiods{nPer+1,'StartEEG'} - 1;
        if StartEEG < EndEEG % they are directly adjacent, so don't do anything
            EEG.data(:, StartEEG:EndEEG) = NaN; % convert to integer to avoid unnecessary matlab warning
        end
    end
end
clear nPer StartEEG EndEEG

% NaN data during bad data
Event = EEG.event;
badIdx = find(ismember({Event.type},PARAM.badData));
badIdx = int32(floor(badIdx)); % convert to integer to avoid unnecessary matlab warning
if ~isempty(badIdx)
    for ibad = badIdx % loop on bad data event
        EEG.data(:,int32(floor(Event(ibad).latency)):int32(floor(Event(ibad).latency+Event(ibad).duration-1))) = NaN; % convert to integer to avoid unnecessary matlab warning
    end
else
    warning('No bad data markers in your recording. You should be sure to movement artifact your data before spindle detection.')
end
clear Event badIdx ibad

end