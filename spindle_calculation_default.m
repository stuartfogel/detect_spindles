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
PARAM.minSpDur = 0.5; % minimum spindle duration in sec. Default = 0.5.
PARAM.type = 13.5; % frequency (Hz) boundary between slow and fast spindles. Default = 13.5.
PARAM.channels = {'Fz','Cz','Pz'}; % channels to extract spindle info. Default = {'Fz','Cz','Pz'}.
PARAM.stages = {'NREM2','NREM3'}; % channels to extract spindle info. Default = {'NREM2','NREM3'}.

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
    for nstage = 1:length(PARAM.stages)
        allTypeFilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_' char(PARAM.stages(nstage)) '.xlsx']; % all spindle type
        slowfilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_' char(PARAM.stages(nstage)) '_<_' num2str(PARAM.type) 'Hz.xlsx']; % slow spindles
        fastfilename = [PARAM.resultDir filesep char(PARAM.channels(nch)) '_' char(PARAM.stages(nstage)) '_>_' num2str(PARAM.type) 'Hz.xlsx']; % fast spindles
        for nfile = 1:length(PARAM.filename)
            % export to excel individual data
            sheetname = char(PARAM.filename(nfile));
            sheetname = sheetname(1:end-4);
            sheetname(isspace(sheetname)) = [];
            % write to xlsx
            writetable(perStageData{nfile,nch,nstage},allTypeFilename,'Sheet',sheetname)
            writetable(struct2table(PARAM),allTypeFilename,'Sheet',1)
            writetable(data{nfile,nch,nstage,1},slowfilename,'Sheet',sheetname)
            writetable(struct2table(PARAM),slowfilename,'Sheet',1)
            writetable(data{nfile,nch,nstage,2},fastfilename,'Sheet',sheetname)
            writetable(struct2table(PARAM),fastfilename,'Sheet',1)
        end
    end
end

clear allTypeFilename slowfilename fastfilename sheetname

%% Export summary data to excel

% create empty cell structures
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
        for nstage = 1:length(PARAM.stages)
            sheetname = char(PARAM.filename(nfile));
            sheetname = sheetname(1:end-4);
            ID{nfile} = sheetname;
            % all spindles
            NumberAllType{nfile,nch,nstage} = sum(height([perStageData{nfile,nch,nstage};NumberAllType{nfile,nch,nstage}]));
            DurationAllType{nfile,nch,nstage} = mean([perStageData{nfile,nch,nstage}.duration;DurationAllType{nfile,nch,nstage}]);
            FrequencyAllType{nfile,nch,nstage} = mean([perStageData{nfile,nch,nstage}.frequency;FrequencyAllType{nfile,nch,nstage}]);
            AmplitudeAllType{nfile,nch,nstage} = mean([perStageData{nfile,nch,nstage}.peakAmplitude;AmplitudeAllType{nfile,nch,nstage}]);
            % slow spindles
            NumberSlow{nfile,nch,nstage,1} = sum(height([data{nfile,nch,nstage,1};NumberSlow{nfile,nch,nstage,1}]));
            DurationSlow{nfile,nch,nstage,1} = mean([data{nfile,nch,nstage,1}.duration;DurationSlow{nfile,nch,nstage,1}]);
            FrequencySlow{nfile,nch,nstage,1} = mean([data{nfile,nch,nstage,1}.frequency;FrequencySlow{nfile,nch,nstage,1}]);
            AmplitudeSlow{nfile,nch,nstage,1} = mean([data{nfile,nch,nstage,1}.peakAmplitude;AmplitudeSlow{nfile,nch,nstage,1}]);
            % fast spindles
            NumberFast{nfile,nch,nstage,2} = sum(height([data{nfile,nch,nstage,2};NumberFast{nfile,nch,nstage,2}]));
            DurationFast{nfile,nch,nstage,2} = mean([data{nfile,nch,nstage,2}.duration;DurationFast{nfile,nch,nstage,2}]);
            FrequencyFast{nfile,nch,nstage,2} = mean([data{nfile,nch,nstage,2}.frequency;FrequencyFast{nfile,nch,nstage,2}]);
            AmplitudeFast{nfile,nch,nstage,2} = mean([data{nfile,nch,nstage,2}.peakAmplitude;AmplitudeFast{nfile,nch,nstage,2}]);
        end
    end
end

% Put it all in tables & write to excel
for nch = 1:length(PARAM.channels)
    for nstage = 1:length(PARAM.stages)
        % create tables
        stageNames = PARAM.stages{nstage};
        stageNames(isspace(stageNames)) = [];
        SummaryAll = table(ID', [NumberAllType{:,nch,nstage}]',[DurationAllType{:,nch,nstage}]',[FrequencyAllType{:,nch,nstage}]',[AmplitudeAllType{:,nch,nstage}]');
        SummaryAll.Properties.VariableNames = {'ID',[char(PARAM.channels(nch)) '_' stageNames '_Number_'],[char(PARAM.channels(nch)) '_' stageNames '_Duration_'],[char(PARAM.channels(nch)) '_' stageNames '_Frequency_'],[char(PARAM.channels(nch)) '_' stageNames '_Amplitude_']};
        SummarySlow = table(ID', [NumberSlow{:,nch,nstage,1}]',[DurationSlow{:,nch,nstage,1}]',[FrequencySlow{:,nch,nstage,1}]',[AmplitudeSlow{:,nch,nstage,1}]');
        SummarySlow.Properties.VariableNames = {'ID',[char(PARAM.channels(nch)) '_' stageNames '_Number_'],[char(PARAM.channels(nch)) '_' stageNames '_Duration_'],[char(PARAM.channels(nch)) '_' stageNames '_Frequency_'],[char(PARAM.channels(nch)) '_' stageNames '_Amplitude_']};
        SummaryFast = table(ID', [NumberFast{:,nch,nstage,2}]',[DurationFast{:,nch,nstage,2}]',[FrequencyFast{:,nch,nstage,2}]',[AmplitudeFast{:,nch,nstage,2}]');
        SummaryFast.Properties.VariableNames = {'ID',[char(PARAM.channels(nch)) '_' stageNames '_Number_'],[char(PARAM.channels(nch)) '_' stageNames '_Duration_'],[char(PARAM.channels(nch)) '_' stageNames '_Frequency_'],[char(PARAM.channels(nch)) '_' stageNames '_Amplitude_']};
        % write to xlsx
        writetable(SummaryAll,[PARAM.resultDir filesep 'SpindleSummaryData' char(PARAM.channels(nch)) char(PARAM.stages(nstage)) '.xlsx'],'Sheet','SummaryAll')
        writetable(SummarySlow,[PARAM.resultDir filesep 'SpindleSummaryData' char(PARAM.channels(nch)) char(PARAM.stages(nstage)) '.xlsx'],'Sheet','SummarySlow')
        writetable(SummaryFast,[PARAM.resultDir filesep 'SpindleSummaryData' char(PARAM.channels(nch)) char(PARAM.stages(nstage)) '.xlsx'],'Sheet','SummaryFast')
    end
end

disp('ALL DONE!!!')

end
