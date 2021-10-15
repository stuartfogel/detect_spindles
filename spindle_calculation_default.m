function spindle_calculation_default()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Calculate spindle data summary (from .csv format output)
%
% Info:     Opens csv output from 'detect_spindles' pipeline and computes
%           summary stats.
%
% Download: https://github.com/stuartfogel/detect_spindles
%
% Author:   Stuart Fogel, PhD, University of Ottawa, School of Psychology
%           Sleep Research Laboratory
%           Copyright (C) Stuart fogel, 2018
%           See the GNU General Public License for more details.
%
% Contact:  sfogel@uottawa.ca
%
% Date:     April 9, 2018
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

%% User defined parameters
PARAM.minSpDur = 0.249; % minimum spindle duration in sec. Default = 0.49.
PARAM.type = 13.5; % frequency (Hz) boundary between slow and fast spindles. Default = 13.5.
PARAM.channels = {'Fz','Cz','Pz'}; % channels to extract spindle info. Default = {'Fz','Cz','Pz'}.
PARAM.stages = {'N2','N3'}; % channels to extract spindle info. Default = {'N2','N3'}.

%% Specify filename(s)
% you can manually specify filenames here, or leave empty for pop-up
PARAM.pathname = ''; % directory where csv files are located
PARAM.filename = ''; % names of csv files
PARAM.resultDir = ''; % directory to save results output

%% Open interface to select *.csv file(s)
if isempty(PARAM.filename)
    disp('Please select the files to process.');
    [filename,pathname] = uigetfile(   {'*.csv', 'comma-separated file (*.CSV)'; ...
        '*.*', 'All Files (*.*)'}, ...
        'Choose files to process', ...
        'Multiselect', 'on');
end

% check the filename(s)
if isequal(filename,0) % no files were selected
    disp('User selected Cancel')
    return;
else
    if ischar(filename) % only one file was selected
        filename = cellstr(filename); % put the filename in the same cell structure as multiselect
    end
end

PARAM.filename = filename;
PARAM.pathname = pathname;

%% Output directory
if isempty(PARAM.resultDir)
    disp('Please select a directory in which to save the results.');
    resultDir = uigetdir('', 'Select the directory in which to save the results');
end

PARAM.resultDir = resultDir;

clear filename pathname resultDir

%% Separate into spindles from specified duration, channel, stage, type (defined above)

[tables, data] = deal(cell(size(PARAM.filename))); % preallocate temp holding vars for loading data

for nfile = 1:length(PARAM.filename)
    % read in raw data to table format
    tables{nfile} = readtable([char(PARAM.pathname) char(PARAM.filename(nfile))]);
    % take only spindles > minSpDur
    cleanidx = tables{nfile}.duration >= PARAM.minSpDur;
    data{nfile} = tables{nfile}(cleanidx,:);
    % take only spindles from specified channel
    for nch = 1:length(PARAM.channels)
        perChannelidx = strcmp(PARAM.channels(nch),data{nfile}.channel);
        perChanData{nfile,nch} = data{nfile}(perChannelidx,:);
        % take only spindles from specified sleep stages
        for nstage = 1:length(PARAM.stages)
            perStageidx = strcmp(PARAM.stages(nstage),perChanData{nfile,nch}.SleepStage);
            perStageData{nfile,nch,nstage} = perChanData{nfile,nch}(perStageidx,:);
            if ~isempty(PARAM.type)
                % separate into slow and fast spindles
                slowidx = perStageData{nfile,nch,nstage}.frequency<PARAM.type;
                perTypeData{nfile,nch,nstage,1} = perStageData{nfile,nch,nstage}(slowidx,:);
                fastidx = perStageData{nfile,nch,nstage}.frequency>PARAM.type;
                perTypeData{nfile,nch,nstage,2} = perStageData{nfile,nch,nstage}(fastidx,:);
            end
        end
    end
    % put all that good stuff back into "data"
    clear data
    data = perTypeData;
end

clear cleanidx perChannelidx perStageidx slowidx fastidx nfile nch nstage

warning( 'off', 'MATLAB:xlswrite:AddSheet' );

%% Export per channel per stage per type to excel
for nch = 1:length(PARAM.channels)
    % NREM stages combined
    allTypeFilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_NREM_all.xlsx']; % all spindle type
    slowfilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_NREM_slow.xlsx']; % slow spindles
    fastfilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_NREM_fast.xlsx']; % fast spindles
    for nfile = 1:length(PARAM.filename)
        % export to excel individual data
        sheetname = char(PARAM.filename(nfile)); % create worksheet name from filename
        sheetname = sheetname(1:end-4); % remove filetype from filename
        sheetname(isspace(sheetname)) = []; % remove any spaces from sheetname
        % write to xlsx
        if length(sheetname)>30
            error('Input file name too long. Please rename files with shorter names.')
        else
            fprintf('Exporting "%s" spindle data during NREM - #%.2i of %.2i...\n', PARAM.channels{nch}, nfile, length(PARAM.filename))
             % export all spindle info to Excel
            writetable(vertcat(perStageData{nfile,nch,:}), allTypeFilename, 'Sheet', sheetname)
            writetable(struct2table(PARAM),allTypeFilename,'Sheet',1)
             % export slow spindle info
            writetable(vertcat(data{nfile,nch,:,1}),slowfilename,'Sheet',sheetname)
            writetable(struct2table(PARAM),slowfilename,'Sheet',1)
             % export fast spindle info
            writetable(vertcat(data{nfile,nch,:,2}),fastfilename,'Sheet',sheetname)
            writetable(struct2table(PARAM),fastfilename,'Sheet',1)
        end
    end
    clear allTypeFilename slowfilename fastfilename sheetname
    
     % NREM stages separately
    for nstage = 1:length(PARAM.stages)
        allTypeFilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_' char(PARAM.stages(nstage)) '.xlsx']; % all spindle type
        slowfilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_' char(PARAM.stages(nstage)) '_slow.xlsx']; % slow spindles
        fastfilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_' char(PARAM.stages(nstage)) '_fast.xlsx']; % fast spindles
        for nfile = 1:length(PARAM.filename)
            % export to excel individual data
            sheetname = char(PARAM.filename(nfile));
            sheetname = sheetname(1:end-4);
            sheetname(isspace(sheetname)) = [];
            % write to xlsx
            if length(sheetname)>30
                error('Input file name too long. Please rename files with shorter names.')
            else
                fprintf('Exporting "%s" spindle data during %s - #%.2i of %.2i...\n', PARAM.channels{nch}, PARAM.stages{nstage}, nfile, length(PARAM.filename))
                writetable(perStageData{nfile,nch,nstage},allTypeFilename,'Sheet',sheetname)
                writetable(struct2table(PARAM),allTypeFilename,'Sheet',1)
                writetable(data{nfile,nch,nstage,1},slowfilename,'Sheet',sheetname)
                writetable(struct2table(PARAM),slowfilename,'Sheet',1)
                writetable(data{nfile,nch,nstage,2},fastfilename,'Sheet',sheetname)
                writetable(struct2table(PARAM),fastfilename,'Sheet',1)
            end
        end
    end
end

clear allTypeFilename slowfilename fastfilename sheetname

%% Export summary data to excel

% create empty cell structures for NREM combined data
NREM_NumberAllType{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_DurationAllType{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_FrequencyAllType{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_AmplitudeAllType{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_NumberSlow{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_DurationSlow{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_FrequencySlow{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_AmplitudeSlow{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_NumberFast{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_DurationFast{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_FrequencyFast{length(PARAM.filename),length(PARAM.channels)} = [];
NREM_AmplitudeFast{length(PARAM.filename),length(PARAM.channels)} = [];

% create empty cell structures for "stage divided" data
NumberAllType{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages)} = [];
DurationAllType{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages)} = [];
FrequencyAllType{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages)} = [];
AmplitudeAllType{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages)} = [];
NumberSlow{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),1} = [];
DurationSlow{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),1} = [];
FrequencySlow{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),1} = [];
AmplitudeSlow{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),1} = [];
NumberFast{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),2} = [];
DurationFast{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),2} = [];
FrequencyFast{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),2} = [];
AmplitudeFast{length(PARAM.filename),length(PARAM.channels),length(PARAM.stages),2} = [];

% calculate means for each channel, stage and type
for nfile = 1:length(PARAM.filename)
    for nch = 1:length(PARAM.channels)
        
        % means for each channel and type for N2 and N3 combined
        sheetname = char(PARAM.filename(nfile));
        sheetname = sheetname(1:end-4);
        NREM_ID{nfile} = sheetname;
        
         % all spindles for NREM sleep
        NREM_NumberAllType{nfile, nch}   = height(vertcat(perStageData{nfile,nch,:}));
        NREM_DurationAllType{nfile,nch}  = nanmean(vertcat(perStageData{nfile,nch,:}).duration);
        NREM_FrequencyAllType{nfile,nch} = nanmean(vertcat(perStageData{nfile,nch,:}).frequency);
        NREM_AmplitudeAllType{nfile,nch} = nanmean(vertcat(perStageData{nfile,nch,:}).amplitude);
        
         % slow spindles during NREM sleep
        NREM_NumberSlow{nfile, nch}     = height(vertcat(data{nfile,nch,:,1}));
        NREM_DurationSlow{nfile, nch}   = nanmean(vertcat(data{nfile,nch,:,1}).duration);
        NREM_FrequencySlow{nfile, nch}  = nanmean(vertcat(data{nfile,nch,:,1}).frequency); 
        NREM_AmplitudeSlow{nfile, nch}  = nanmean(vertcat(data{nfile,nch,:,1}).amplitude);
        
         % fast spindles during NREM sleep
        NREM_NumberFast{nfile, nch}     = height(vertcat(data{nfile,nch,:,2}));
        NREM_DurationFast{nfile, nch}   = nanmean(vertcat(data{nfile,nch,:,2}).duration);
        NREM_FrequencyFast{nfile, nch}  = nanmean(vertcat(data{nfile,nch,:,2}).frequency);
        NREM_AmplitudeFast{nfile, nch}  = nanmean(vertcat(data{nfile,nch,:,2}).amplitude);
        
        for nstage = 1:length(PARAM.stages)
            sheetname = char(PARAM.filename(nfile));
            sheetname = sheetname(1:end-4);
            ID{nfile} = sheetname;
            % all spindles
            NumberAllType{nfile,nch,nstage} = sum(height([perStageData{nfile,nch,nstage};NumberAllType{nfile,nch,nstage}]));
            DurationAllType{nfile,nch,nstage} = mean([perStageData{nfile,nch,nstage}.duration;DurationAllType{nfile,nch,nstage}]);
            FrequencyAllType{nfile,nch,nstage} = mean([perStageData{nfile,nch,nstage}.frequency;FrequencyAllType{nfile,nch,nstage}]);
            AmplitudeAllType{nfile,nch,nstage} = mean([perStageData{nfile,nch,nstage}.amplitude;AmplitudeAllType{nfile,nch,nstage}]);
            % slow spindles
            NumberSlow{nfile,nch,nstage,1} = sum(height([data{nfile,nch,nstage,1};NumberSlow{nfile,nch,nstage,1}]));
            DurationSlow{nfile,nch,nstage,1} = mean([data{nfile,nch,nstage,1}.duration;DurationSlow{nfile,nch,nstage,1}]);
            FrequencySlow{nfile,nch,nstage,1} = mean([data{nfile,nch,nstage,1}.frequency;FrequencySlow{nfile,nch,nstage,1}]);
            AmplitudeSlow{nfile,nch,nstage,1} = mean([data{nfile,nch,nstage,1}.amplitude;AmplitudeSlow{nfile,nch,nstage,1}]);
            % fast spindles
            NumberFast{nfile,nch,nstage,2} = sum(height([data{nfile,nch,nstage,2};NumberFast{nfile,nch,nstage,2}]));
            DurationFast{nfile,nch,nstage,2} = mean([data{nfile,nch,nstage,2}.duration;DurationFast{nfile,nch,nstage,2}]);
            FrequencyFast{nfile,nch,nstage,2} = mean([data{nfile,nch,nstage,2}.frequency;FrequencyFast{nfile,nch,nstage,2}]);
            AmplitudeFast{nfile,nch,nstage,2} = mean([data{nfile,nch,nstage,2}.amplitude;AmplitudeFast{nfile,nch,nstage,2}]);
        end
    end
end

% Put it all in tables & write to excel
for nch = 1:length(PARAM.channels)
    
    % write tables for N2 and N3 combined
    chNames = PARAM.channels{nch};
    chNames(strfind(chNames,'-')) = []; % delete hyphen (re; character not allowed)
     % all spindles (slow and fast combined)
    SummaryAll = table(NREM_ID', [NREM_NumberAllType{:,nch}]',[NREM_DurationAllType{:,nch}]',[NREM_FrequencyAllType{:,nch}]',[NREM_AmplitudeAllType{:,nch}]');
    SummaryAll.Properties.VariableNames = {'ID',[chNames '_NREM_Number'],[chNames '_NREM_Duration'],[chNames '_NREM_Frequency'],[chNames '_NREM_Amplitude']};
     % slow spindles
    SummarySlow = table(NREM_ID', [NREM_NumberSlow{:,nch}]',[NREM_DurationSlow{:,nch}]',[NREM_FrequencySlow{:,nch}]',[NREM_AmplitudeSlow{:,nch}]');
    SummarySlow.Properties.VariableNames = {'ID',[chNames '_NREM_Number'],[chNames '_NREM_Duration'],[chNames '_NREM_Frequency'],[chNames '_NREM_Amplitude']};
     % fast spindles
    SummaryFast = table(NREM_ID', [NREM_NumberFast{:,nch}]',[NREM_DurationFast{:,nch}]',[NREM_FrequencyFast{:,nch}]',[NREM_AmplitudeFast{:,nch}]');
    SummaryFast.Properties.VariableNames = {'ID',[chNames '_NREM_Number'],[chNames '_NREM_Duration'],[chNames '_NREM_Frequency'],[chNames '_NREM_Amplitude']};
    % write to xlsx
    fprintf('Writing summary tables for channel "%s" during NREM to Excel...\n', chNames)
    writetable(SummaryAll,[PARAM.resultDir filesep 'SpindleSummaryData' chNames '_NREM.xlsx'],'Sheet','SummaryAll')
    writetable(SummarySlow,[PARAM.resultDir filesep 'SpindleSummaryData' chNames '_NREM.xlsx'],'Sheet','SummarySlow')
    writetable(SummaryFast,[PARAM.resultDir filesep 'SpindleSummaryData' chNames '_NREM.xlsx'],'Sheet','SummaryFast')
    
    for nstage = 1:length(PARAM.stages)
        % create tables
        stageNames = PARAM.stages{nstage};
        stageNames(isspace(stageNames)) = []; % delete whitespace
        chNames = char(PARAM.channels(nch));
        chNames(strfind(chNames,'-')) = []; % delete hyphen (re; character not allowed)
        SummaryAll = table(ID', [NumberAllType{:,nch,nstage}]',[DurationAllType{:,nch,nstage}]',[FrequencyAllType{:,nch,nstage}]',[AmplitudeAllType{:,nch,nstage}]');
        SummaryAll.Properties.VariableNames = {'ID',[chNames '_' stageNames '_Number'],[chNames '_' stageNames '_Duration'],[chNames '_' stageNames '_Frequency'],[chNames '_' stageNames '_Amplitude']};
        SummarySlow = table(ID', [NumberSlow{:,nch,nstage,1}]',[DurationSlow{:,nch,nstage,1}]',[FrequencySlow{:,nch,nstage,1}]',[AmplitudeSlow{:,nch,nstage,1}]');
        SummarySlow.Properties.VariableNames = {'ID',[chNames '_' stageNames '_Number'],[chNames '_' stageNames '_Duration'],[chNames '_' stageNames '_Frequency'],[chNames '_' stageNames '_Amplitude']};
        SummaryFast = table(ID', [NumberFast{:,nch,nstage,2}]',[DurationFast{:,nch,nstage,2}]',[FrequencyFast{:,nch,nstage,2}]',[AmplitudeFast{:,nch,nstage,2}]');
        SummaryFast.Properties.VariableNames = {'ID',[chNames '_' stageNames '_Number'],[chNames '_' stageNames '_Duration'],[chNames '_' stageNames '_Frequency'],[chNames '_' stageNames '_Amplitude']};
        % write to xlsx
        fprintf('Writing summary tables for channel "%s" during %s to Excel...\n', chNames, stageNames)
        writetable(SummaryAll,[PARAM.resultDir filesep 'SpindleSummaryData' chNames char(PARAM.stages(nstage)) '.xlsx'],'Sheet','SummaryAll')
        writetable(SummarySlow,[PARAM.resultDir filesep 'SpindleSummaryData' chNames char(PARAM.stages(nstage)) '.xlsx'],'Sheet','SummarySlow')
        writetable(SummaryFast,[PARAM.resultDir filesep 'SpindleSummaryData' chNames char(PARAM.stages(nstage)) '.xlsx'],'Sheet','SummaryFast')
    end
end

disp('ALL DONE!!!')

end
