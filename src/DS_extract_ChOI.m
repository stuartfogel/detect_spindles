function EEG = DS_extract_ChOI(EEG,PARAM)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Function to extract only channels of interest for pipeline
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

if isfield(PARAM,'channels_of_interest')
    if ~isempty(PARAM.channels_of_interest)
        
        ChName = {EEG.chanlocs.labels};
        if iscell(PARAM.channels_of_interest)
            ChOI = PARAM.channels_of_interest;
        else
            ChOI = {PARAM.channels_of_interest};
        end
        
        iChOI = false(size(ChName));
        for i = 1:length(ChOI)
            iChOI = logical(iChOI + strcmp(ChName,ChOI{i}));
        end
        
        EEG.data = EEG.data(iChOI,:);
        EEG.chanlocs = EEG.chanlocs(iChOI);
        EEG.nbchan = length(ChOI);
        
    end
end

end