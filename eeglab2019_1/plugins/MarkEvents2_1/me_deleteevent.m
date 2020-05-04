function [EEG] = me_deleteevent(EEG,g,lat1,lat2)
    ug=g;
    l1=lat1(1);
    l2=lat2(1);
    if l1>l2
        l1=lat2(1);
        l2=lat1(1);
    end
    ug.WinStartPnt=ug.time; 
    l1=l1+(ug.WinStartPnt*ug.srate);
    l2=l2+(ug.WinStartPnt*ug.srate);
    i=1;
    event_index=[];
    for nevt=1:length(ug.events)
        index = find(ug.events(nevt).latency > l1 & ug.events(nevt).latency+ug.events(nevt).duration < l2);
        if index == 1
            event_index(i) = nevt;
            i=i+1;
        end
    end    
    if ~isempty(event_index)
        ug.events(event_index)=[];
        ug.eventstyle(event_index)=[];
        ug.eventwidths(event_index)=[];
        ug.eventlatencies(event_index)=[];
        ug.eventlatencyend(event_index)=[];
        ug.eventcolors(event_index)=[];
        set(gcf,'UserData',ug);
    end
    EEG.event=ug.events;
    clear event_index g i index l1 l2 lat1 lat2 nevt nind ug
    me_eegplot('drawp',0)
end