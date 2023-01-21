function DS_export_Spindles_csv(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Export spindle events to CSV file
%
% Part of detect_spindles toolbox:
%
% Authors:  Stephane Sockeel, PhD, University of Montreal
%           Stuart Fogel, PhD, University Ottawa
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

Mrk = EEG.event;
nbMrk = length(Mrk);

for i = 1:nbMrk
    Mrk(i).latency = Mrk(i).latency/EEG.srate; % convert to seconds
    Mrk(i).duration = Mrk(i).duration/EEG.srate; % convert to seconds
    if isfield(Mrk,'peak')
        Mrk(i).peak = Mrk(i).peak/EEG.srate; % convert to seconds
    end
    if isfield(Mrk,'channel')
        if Mrk(i).channel == 0 % some file importers indicate no channel as [0] instead of []
            Mrk(i).channel = [];
        elseif isnan(Mrk(i).channel) % some file importers indicate no channel as NaN instead of []
            Mrk(i).channel = [];
        elseif isempty(Mrk(i).channel) % some events have empty channels '' instead of []
            Mrk(i).channel = [];
        else
            Mrk(i).channel = Mrk(i).channel;
        end
    else
        Mrk(i).channel = 'none';
    end
end

NameFields = fieldnames(Mrk);
nbFields = length(NameFields);
FileName = [EEG.filepath EEG.setname '.csv'];
fid = fopen(FileName,'w');
towrite = '';

for i = 1:nbFields
    towrite  = [towrite NameFields{i} ','];
end
towrite(end) = []; % last ',' out
fprintf(fid,'%s\n',towrite);
for iMrk = 1:nbMrk
    towrite = '';
    if strcmpi(Mrk(iMrk).type,PARAM.eventName)
        for i = 1:nbFields
            towrite  = [towrite instring(Mrk(iMrk).(NameFields{i})) ','];
        end
        towrite(end) = []; % last ',' out
        fprintf(fid,'%s\n',towrite);
    end
end
fclose(fid);

end

function stra = instring(a)

if ~ischar(a)
    stra = num2str(a);
else
    stra =a;
end

end
