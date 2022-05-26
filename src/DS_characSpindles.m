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
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if ~isfield(PARAM,'eventName')
    PARAM.eventName = 'Spindle';
end

indlogicalSpindles = strcmpi({EEG.event.type},PARAM.eventName);
indSpindle = find(indlogicalSpindles);

if ~isfield(EEG.event,'channel')
    prompt = 'Channel info missing. Enter channel index (e.g., 1) ';
    channel = input(prompt);
end

for iSpin = indSpindle
    Spindle  = EEG.event(iSpin);
    if ~isfield(Spindle,'channel')
        if strcmpi(Spindle.type,PARAM.eventName)
            Spindle.channel = channel;
        end
    end
    sp_beg = Spindle.latency;
    sp_end = Spindle.duration + sp_beg;
    data = EEG.data(Spindle.channel,sp_beg:sp_end);
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
