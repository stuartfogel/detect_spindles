function [EEG, marker, PARAM] = DS_pipeline_detect_spindles(EEG,PARAM,OutputFile,OutputPath)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Pipeline to detect Spindles in EEG data
%
% INPUT:    EEG = EEGLab structure
%           PARAM = structure of parameters. See detect_spindles.m.
%
% OUTPUT:   EEG = same structure with spindle markers (EEG.event)
%           marker = spindle markers
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

% just for debug, or if you need to keep each processing step :
Output_All = 0;
if isfield(PARAM,'output_allfiles')
    if PARAM.output_allfiles
        Output_All = 1;
    end
end

%% 0) Start pipeline
t0 = clock; % start time
fprintf(1,'%s\n',['------------------------ ' datestr(t0) ' ------------------------']);

% Check data format for compatibility. Ensure EEG.data are double (filtfilt requirement). This also resolves other related issues.
EEG.data = double(EEG.data);
if Output_All
    ALLEEG(1) = EEG;
    ALLEEG(1).setname = 'raw data';
end

%% 1) COMPLEX DEMODULATION OR RMS

% 1a) channels of interest
if ~isempty(PARAM.channels_of_interest)
    EEGcoi = DS_extract_ChOI(EEG,PARAM);
end

% 1b) if complex demodulation is your preference
if PARAM.cdemodORrms == 1
    fprintf(1,'%s\n',' ');
    fprintf(1,'%s\n','STEP 1: COMPLEX DEMODULATION');
    EEGfreq = DS_complexDemodulation(EEGcoi,PARAM);
    if Output_All
        ALLEEG(2) = EEGfreq;
        ALLEEG(2).setname = 'ComplexDemod';
    end
% 1c) if RMS is your weapon of choice
elseif PARAM.cdemodORrms == 0
    fprintf(1,'%s\n',' ');
    fprintf(1,'%s\n','STEP 1: ROOT MEAN SQUARE TRANSFORMATION');
    EEGfreq = DS_rms(EEGcoi,PARAM);
    if Output_All
        ALLEEG(2) = EEGfreq;
        ALLEEG(2).setname = 'RMS';
    end
else
    error('Please choose either complex demodulate or RMS to extract frequencies of interest.')
end

t1 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t1,t0)) ' sec.']);

%% 2) Z-SCORE NORMALIZATION

fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 2: Z-SCORE NORMALIZATION');

% 2a) set data during movements to NaN so they don't contaminate normalization 
EEGnan = DS_NaNbadData(EEGfreq,PARAM);

% 2b) Signal normalization
EEGz = DS_Zscore_new(EEGnan,PARAM);
if Output_All
    ALLEEG(3) = EEGz;
    ALLEEG(3).setname = 'ZScore';
end

t2 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t2,t1)/60) ' min.']);

%% 3) SPINDLE DETECTION
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 3: SPINDLE DETECTION');

% delete the previous mrk in the new struct
EEGs.event = [];
EEGs.urevent = [];
EEGs = EEGz;

% detect spindles
[EEGs, marker] = DS_Threshold(EEGs,PARAM);
if Output_All
    ALLEEG(4) = EEGs;
    ALLEEG(4).setname = 'ZScore_with_spindles';
end

% spindle merge events back with existing events and original data:
EEG = DS_merge_event(EEG,EEGs);

if Output_All
    ALLEEG(5) = EEG;
    ALLEEG(5).setname = 'Raw_Data with Spindles';
end

t3 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t3,t2)/60) ' min.']);

%% 4) REMOVE SPINDLES OUTSIDE NREM
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 4: REMOVE SPINDLES OUTSIDE NREM');

if ~isempty(PARAM.goodsleepstages)
    EEG = DS_remBadSleepStage(EEG, PARAM);
    t4 = clock;
else
    t4 = clock;
    disp('Removed spindles from outside NREM skipped')
end

fprintf(1,'%s\n',[' ~~ ' num2str(etime(t4,t3)/60) ' min.']);

%% 5) REMOVE SPINDLES DURING MOVEMENT ARTIFACT
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 5: REMOVE SPINDLES DURING MOVEMENT ARTIFACT');

EEG = DS_remBadMinMax(EEG, PARAM);

t5 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t5,t4)/60) ' min.']);

%% 6) SPINDLE CHARACTERIZATION
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 6: SPINDLE CHARACTERIZATION');

EEG = DS_characSpindles(EEG, PARAM);

if Output_All
    ALLEEG(6) = EEG;
    ALLEEG(6).setname = 'Final product';
end

t6 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t6,t5)/60) ' min.']);

%% 7) EXPORT SPINDLE MARKERS
fprintf(1,'%s\n',' ');
fprintf(1,'%s\n','STEP 7: EXPORT SPINDLE MARKERS');

if isfield(PARAM,'save_result_file')
    if isempty(PARAM.save_result_file)
        [OutputFile, OutputPath] = uiputfile({'*.csv','CSV Files (*.csv)';'*.*','All Files'},'Export MarkerFiles ?');
        if OutputFile ~= 0
            export_Spindles_csv([OutputPath OutputFile '.csv'],EEG);
        end
    elseif ~isempty(PARAM.save_result_file)
        export_Spindles_csv([OutputPath OutputFile '.csv'],EEG);
    end
end

t7 = clock;
fprintf(1,'%s\n',[' ~~ ' num2str(etime(t7,t6)/60) ' min.']);

if Output_All
    EEG = ALLEEG;
end

end
