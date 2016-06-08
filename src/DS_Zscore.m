function ZS = DS_Zscore(CD,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Normalize EEG signal using sliding window
%
% Part of detect_spindles toolbox:
%
% Authors:  Stephane Sockeel, PhD, University of Montreal
%           Stuart Fogel, PhD, Western University
%           Thanks to support from Julien Doyon and input from Arnaud Bore.
%           Copyright (C) Stuart fogel & Stephane Sockeel, 2016
%           See the GNU General Public License for more details.
%
% Contact:  sfogel@uwo.ca
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
MID_WIN = round(WIN/2); % pour rester int, c'est la valeur de temps reference
nb_channels = size(CD.data,1);
nb_points = size(CD.data,2);

% zscore_eegData=[];
zscore_all_eegData=zeros(size(CD.data));

% % % % % % % % % % %
% LOOP
% updated 'for' loop to 'parfor' for super-fast parallel processing!!!!
% for channel=1:nb_channels
% Setup pool of workers
if ~isempty(gcp)
    delete(gcp('nocreate')) % delete current pool to start a new one
end
cpus = feature('numCores'); % get number of cores
poolsize = cpus - 1; % to use all but one core
parpool('local',poolsize); % create pool with n-1 cores

parfor channel=1:nb_channels
    disp(['Z-transforming channel ' num2str(channel) ' of ' num2str(nb_channels) '. This will take a while...'])
    fprintf(1,'%s\n',['channel ' int2str(channel)]);
    % Set DATA to
    Data = CD.data(channel,:);
    zscore_eegData=zeros(1,nb_points);
    
    str = '';
    
    if WIN>nb_points
        
        zscore_eegData = (Data - mean(Data))/std(Data);
        
    else
        for pt=1:MID_WIN+1
            zscore_eegData(pt)=(Data(pt)-mean(Data(1:(MID_WIN*2+1))))/std(Data(1:(MID_WIN*2+1)));
        end
        
        for pt=(MID_WIN+2):(nb_points-MID_WIN)
            zscore_eegData(pt)=(Data(pt)-mean(Data((pt-MID_WIN):(pt+MID_WIN))))/std(Data((pt-MID_WIN):(pt+MID_WIN)));
        end
        
        for pt=(nb_points-MID_WIN+1):nb_points
            zscore_eegData(pt)=(Data(pt)-mean(Data(nb_points-MID_WIN*2:nb_points)))/std(Data(nb_points-MID_WIN*2:nb_points));
        end
    end
    fprintf(1,[repmat('\b',1,length(str)) '%s\n'],'Done');
    zscore_all_eegData(channel,:)=zscore_eegData(1,:);
end

delete(gcp('nocreate')) % close the pool
clear mid_sliding_window channel pt wrong_index EEGData zscore_eegData length index_tableau index i first_window Data sliding_window channels str strt

ZS = CD;
ZS.data=zscore_all_eegData;

clear zscore_all_eegData

end
