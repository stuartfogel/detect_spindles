function [EEG,PARAM] = DS_complexDemodulation(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% ComplexDemodulation
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

[b, a] = butter(PARAM.cdemod_forder ,  PARAM.cdemod_filter_lowpass / EEG.srate , 'low');

% Complex Demodulation
carArray = exp(-2*pi * 1i * PARAM.cdemod_freq * (0:(size(EEG.data,2) - 1)) / EEG.srate);
for iChan = 1:EEG.nbchan
    for iTrial = 1:EEG.trials
        x = double(EEG.data(iChan, :, iTrial)) .* carArray;
        x = filtfilt(b, a, x);
        if size(x,1)>size(x,2)
            x = x';
        end
        x = smoothing(x,EEG.srate/PARAM.cdemod_freq);
        EEG.data(iChan, :, iTrial) = (real(x).^2 + imag(x).^2);
        % EEG.data(iChan, :, iTrial) = envelope(EEG.data(iChan, :, iTrial),EEG.srate/2,'rms'); % take the envelope of the CD peaks
    end
end

end

function newx = smoothing(x,T)
% smooth using a triangle
a = T:-1:0;
la = length(a)-1;

H = [a(end:-1:2) a];
H = H/sum(H);
tH = -la:la;

newx = zeros(size(x));
long = size(x,2);

for i = 1:long
    newx(:,i) = sum( x(:, max(min(i+tH,long),1)) .* H);
end

end
