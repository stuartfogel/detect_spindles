function ZS = DS_Zscore_new(CD,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Normalize EEG signal using sliding window
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

WIN = round(CD.srate * PARAM.ZSwindowlength); % default (in seconds) PARAM.ZSwindowlength = 60
nb_channels = size(CD.data,1);
nb_points = size(CD.data,2);
zscore_all_eegData=zeros(size(CD.data));

for channel=1:nb_channels
    disp(['Z-transforming channel ' num2str(channel) ' of ' num2str(nb_channels) '.'])
    fprintf(1,'%s\n',['channel ' int2str(channel)]);
    % Set DATA to:
    Data = CD.data(channel,:);
    zscore_eegData=zeros(1,nb_points);
    
    str = '';
    
    Mm = movmean(Data, WIN,'omitnan'); % calculate moving mean
    Mstd = movstd(Data, WIN,'omitnan'); % calculate moving SD
    % calculate z-score
    for pt = 1:length(Data)
        zscore_eegData(pt) = (Data(pt) - Mm(pt))/Mstd(pt);
        if zscore_eegData(pt) < 0
            zscore_eegData(pt) = 0;
        end
    end
    
    fprintf(1,[repmat('\b',1,length(str)) '%s\n'],'Done');
    zscore_all_eegData(channel,:)=zscore_eegData(:);
end

clear channel pt zscore_eegData Data str

ZS = CD;
ZS.data=zscore_all_eegData;

clear zscore_all_eegData zscore_eegData Mm Mstd

end
