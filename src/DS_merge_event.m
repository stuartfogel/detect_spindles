function EEG1 = DS_merge_event(EEG1,EEG2)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Merge events in two EEG structures
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

Mrk1 = EEG1.event;
Mrk2 = EEG2.event;

if isempty(Mrk2)
    % nothing to do
else
    % warning : be careful, if the sampling rates are not the same...
    if EEG1.srate ~= EEG2.srate
        srate_coeff2to1 = EEG1.srate / EEG2.srate;
        for iMrk = 1:length(Mrk2)
            Mrk2(iMrk).latency = round(Mrk2(iMrk).latency * srate_coeff2to1);
            Mrk2(iMrk).duration = round(Mrk2(iMrk).duration * srate_coeff2to1);
            if isfield(Mrk2,'peak') % note: peak is not a default field for EEG.event
                Mrk2(iMrk).peak = round(Mrk2(iMrk).peak * srate_coeff2to1);
            end
        end
    end
    
    % warning : be careful of the channels
    Ch2 = {EEG2.chanlocs.labels};
    Ch1 = {EEG1.chanlocs.labels};
    
    % newCh = corresp. btw channels in set2 and channels in set1
    newCh = zeros(1,length(Ch2));
    for i = 1:length(newCh)
        
        tmp = find(strcmp(Ch1,Ch2{i}));
        if ~isempty(tmp)
            newCh(i) = tmp;
        end
    end
    
    % we apply this to the marker of set2
    for iMrk = 1:length(Mrk2)
        if Mrk2(iMrk).channel
            Mrk2(iMrk).channel = newCh(Mrk2(iMrk).channel);
        end
    end        % so, the channels of Mrk2 correspond to the channels in set1 : we can merge the event
    
    if isempty(Mrk1)
        EEG1.event = Mrk2;
    else
        
        % in this case, it's sure that marker & EEG.event are not empty
        % warning : be care of the possible difference in the fields
        eegfields = fieldnames(Mrk1(1));
        for i = 1:length(eegfields)
            if ~isfield(Mrk2(1),eegfields{i})
                Mrk2(1).(eegfields{i}) = [];
            end
        end
        Mrkfields = fieldnames(Mrk2(1));
        for i = 1:length(Mrkfields)
            if ~isfield(Mrk1(1),Mrkfields{i})
                Mrk1(1).(Mrkfields{i}) = [];
            end
        end
        
        Mrk2 = [Mrk2 Mrk1]; % merge
        [~, triMrk] = sort([Mrk2.latency]);
        Mrk2 = Mrk2(triMrk); % sort by latency
        EEG1.event = Mrk2;
    end
    
    if isfield(EEG1.event,'urevent')
        EEG1.urevent = rmfield(EEG1.event,'urevent');
    else
        EEG1.urevent = EEG1.event;
    end
    for iMrk = 1:length(EEG1.event)
        EEG1.event(iMrk).urevent = iMrk;
    end
end

end