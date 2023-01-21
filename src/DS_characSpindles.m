function EEG = DS_characSpindles(EEG, PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Characterize event amplitude and oscillatory frequency
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

if ~isfield(PARAM,'eventName')
    PARAM.eventName = 'Spindle';
end

indlogicalSpindles = strcmpi({EEG.event.type},PARAM.eventName);
indSpindle = find(indlogicalSpindles);

for iSpin = indSpindle
    Spindle  = EEG.event(iSpin);
    sp_beg = Spindle.latency;
    sp_end = Spindle.duration + sp_beg;
    data = EEG.data(find(ismember({EEG.chanlocs.labels},Spindle.channel)),sp_beg:sp_end);
    data_F = filtering(data, EEG.srate, PARAM);
    EEG.event(iSpin).amplitude = max(max(data_F)-min(data_F));
    EEG.event(iSpin).area = sum(abs(data_F))*1/EEG.srate; % compute integrated amplitude, i.e., absolute area under the curve
    freq = mean(EEG.srate ./ [diff(find((diff(sign(diff(data_F))))>0)) ,  diff(find((diff(sign(diff(data_F))))<0))]);  % frequency : srate divided by the mean of distance btw max pos. peak or min neg. peak
    if PARAM.cdemod_freq - PARAM.cdemod_filter_lowpass/2 - 1 < 1 % for when trying to measure frequencies lower than 1Hz
        if any(isnan(freq))
            freq = 1; % this means that there were only one min and one max, thus, freq below measurable floor <= 1Hz.
        end
    end
    EEG.event(iSpin).frequency = freq;
end

end

function data_F = filtering(data,SRATE,PARAM)
hp = PARAM.cdemod_freq - PARAM.cdemod_filter_lowpass/2 -1; % pad range by 1Hz
lp = PARAM.cdemod_freq + PARAM.cdemod_filter_lowpass/2 +1; % pad range by 1Hz
if hp < 0.25 % ensure lowest frequency is a real, and usable number for filtfilt
    hp = 0.25;
end
[b,a] = butter(2 , [hp lp]/(SRATE/2), 'bandpass');
data_F = filtfilt(b,a, data);
end
