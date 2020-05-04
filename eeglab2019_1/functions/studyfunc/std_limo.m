% std_limo() - Export and run in LIMO the EEGLAB STUDY design.
%           call limo_batch to create all 1st level LIMO_EEG analysis + RFX
%
% Usage:
%   [STUDY LIMO_files] = std_limo(STUDY,ALLEEG,'key',val)
%
% Inputs:
%  STUDY        - studyset structure containing some or all files in ALLEEG
%  ALLEEG       - vector of loaded EEG datasets
%
% Optional inputs:
%  'measure'      - ['daterp'|'icaerp'|'datspec'|'icaspec'|'datersp'|'icaersp']
%                   measure to compute. Currently, only 'daterp' and
%                   'datspec' are supported. Default is 'daterp'.
%  'method'       - ['OLS'|'WTS'|'IRLS'] Ordinary Least Squares (OLS) or Weighted
%                   Least Squares (WTS) or Iterative Reweighted Least Squares'IRLS'.
%                   WTS should be used as it is more robust. IRLS is much slower
%                   and better across subjects than across trials.
%  'design'       - [integer] design index to process. Default is the current
%                   design stored in STUDY.currentdesign.
%  'erase'        - ['on'|'off'] erase previous files. Default is 'on'.
%  'neighboropt'  - [cell] cell array of options for the function computing
%                   the channel neighbox matrix std_prepare_chanlocs(). The file
%                   is saved automatically if channel location are present.
%                   This option allows to overwrite the defaults when computing
%                   the channel neighbox matrix.
%   'chanloc'     - Channel location structure. Must be used with 'neighbormat',
%                   or it will be ignored. If this option is used, it will
%                   ignore 'neighboropt' if used.
%   'neighbormat' - Neighborhood matrix of electrodes. Must be used with 'chanloc',
%                   or it will be ignored. If this option is used, it will
%                   ignore 'neighboropt' if used.
%   'freqlim'     - Frequency trimming in Hz
%   'timelim'     - Time trimming in millisecond
%
% Outputs:
%  STUDY     - modified STUDY structure (the STUDY.design now contains a list
%              of the limo files)
%  LIMO_files a structure with the following fields
%     LIMO_files.LIMO the LIMO folder name where the study is analyzed
%     LIMO_files.mat a list of 1st level LIMO.mat (with path)
%     LIMO_files.Beta a list of 1st level Betas.mat (with path)
%     LIMO_files.con a list of 1st level con.mat (with path)
%     LIMO_files.expected_chanlocs expected channel location neighbor file for
%                                  correcting for multiple comparisons
% Example:
%  [STUDY LIMO_files] = std_limo(STUDY,ALLEEG,'measure','daterp')
%
% Author: Arnaud Delorme, SCCN, 2018 based on a previous version of
%         Cyril Pernet (LIMO Team), The university of Edinburgh, 2014
%         Ramon Martinez-Cancino and Arnaud Delorme

% Copyright (C) 2018 Arnaud Delorm
%
% This file is part of EEGLAB, see http://www.eeglab.org
% for the documentation and details.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above copyright notice,
% this list of conditions and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above copyright notice,
% this list of conditions and the following disclaimer in the documentation
% and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
% THE POSSIBILITY OF SUCH DAMAGE.

function [STUDY, LIMO_files] = std_limo(STUDY,ALLEEG,varargin)

LIMO_files = [];

if isempty(STUDY.filepath)
    STUDY.filepath = pwd;
end
cd(STUDY.filepath);
if nargin < 2
    help std_limo;
    return;
end

warning('off', 'MATLAB:lang:cannotClearExecutingFunction');
if ischar(varargin{1}) && ( strcmpi(varargin{1}, 'daterp') || ...
        strcmpi(varargin{1}, 'datspec') || ...
        strcmpi(varargin{1}, 'dattimef') || ...
        strcmpi(varargin{1}, 'icaerp')|| ...
        strcmpi(varargin{1}, 'icaspec')|| ...
        strcmpi(varargin{1}, 'icatimef'))
    opt.measure  = varargin{1};
    opt.design   = varargin{2};
    opt.erase    = 'on';
    opt.method   = 'OSL';
else
    opt = finputcheck( varargin, ...
        { 'measure'        'string'  { 'daterp' 'datspec' 'dattimef' 'icaerp' 'icaspec' 'icatimef' } 'daterp'; ...
          'method'         'string'  { 'OLS' 'WLS' } 'OLS';
          'design'         'integer' [] STUDY.currentdesign;
          'erase'          'string'  { 'on','off' }   'off';
          'splitreg'       'string'  { 'on','off' }   'off';
          'interaction'    'string'  { 'on','off' }   'off';
          'freqlim'        'real'    []               [] ;
          'timelim'        'real'    []               [] ;
          'neighboropt'    'cell'    {}               {} ;
          'chanloc'        'struct'  {}               struct('no', {}); % default empty structure
          'neighbormat'    'real'    []               [] },...
          'std_limo');
    if ischar(opt), error(opt); end
end
opt.measureori = opt.measure;
if strcmpi(opt.measure, 'datersp')
    opt.measure = 'dattimef';
end

Analysis     = opt.measure;
design_index = opt.design;

% Make sure paths are ok for LIMO (Consider to move this to eeglab.m in a future)
% -------------------------------------------------------------------------
root = fileparts(which('limo_eeg'));
addpath([root filesep 'limo_cluster_functions']);
addpath([root filesep 'external' filesep 'psom']);
addpath([root filesep 'external']);
addpath([root filesep 'help']);

% Checking fieldtrip paths
skip_chanlocs = 0;
if ~exist('ft_prepare_neighbours')
    warndlg('std_limo error: Fieldtrip extension should be installed - chanlocs NOT generated');
    skip_chanlocs = 1;
else
    if ~exist('eeglab2fieldtrip')
        root = fileparts(which('ft_prepare_neighbours'));
        addpath([root filesep 'external' filesep 'eeglab']);
    end
end

% Detecting type of analysis
% -------------------------------------------------------------------------
model.defaults.datatype = opt.measureori(4:end);
if strfind(Analysis,'dat')
    model.defaults.type = 'Channels';
elseif strfind(Analysis,'ica')
    [STUDY,flags]=std_checkdatasession(STUDY,ALLEEG);
    if sum(flags)>0
        error('some subjects have data from different sessions - can''t do ICA');
    end
    model.defaults.type = 'Components';
end

% Checking if clusters
% -------------------------------------------------------------------------
if strcmp(model.defaults.type,'Components')
    if isempty(STUDY.cluster(1).child)
        warndlg2(sprintf('Components have not been clustered,\nLIMO will not match them across subjects'))
        model.defaults.icaclustering = 0;
    else
        model.defaults.icaclustering = 1;
    end
end

% computing channel neighbox matrix
% ---------------------------------
if skip_chanlocs == 0

    flag_ok = 1;
    if isempty(opt.chanloc) && isempty(opt.neighbormat)
        if isfield(ALLEEG(1).chanlocs, 'theta') &&  ~strcmp(model.defaults.type,'Components')
            if  ~isfield(STUDY.etc,'statistic')
                STUDY = pop_statparams(STUDY, 'default');
            end

            try
                [~,~,limoChanlocs] = std_prepare_neighbors(STUDY, ALLEEG, 'force', 'on', opt.neighboropt{:});
                chanlocname = 'limo_gp_level_chanlocs.mat';
            catch neighbors_error
                warndlg2(neighbors_error.message,'limo_gp_level_chanlocs.mat not created')
            end
        else
            limoChanlocs = [];
            flag_ok = 0;
            if ~isempty(STUDY.cluster(1).child)
                disp('Warning: cannot compute expected channel distance for correction for multiple comparisons');
            end
        end
    else
        limoChanlocs.expected_chanlocs   = opt.chanloc;
        limoChanlocs.channeighbstructmat = opt.neighbormat;
        chanlocname = 'limo_chanlocs.mat';
    end
end

if flag_ok % chanloc created
    if isempty(findstr(STUDY.filepath,'derivatives'))
        if ~exist([STUDY.filepath filesep 'derivatives'],'dir')
            mkdir([STUDY.filepath filesep 'derivatives']);
        end
        limoChanlocsFile = fullfile([STUDY.filepath filesep 'derivatives'], chanlocname);
    else
        limoChanlocsFile = fullfile(STUDY.filepath, chanlocname);
    end
    save('-mat', limoChanlocsFile, '-struct', 'limoChanlocs');
    fprintf('Saving channel neighbors for correction for multiple comparisons in %s\n', limoChanlocsFile);
end

% 1st level analysis
% -------------------------------------------------------------------------
model.cat_files  = [];
model.cont_files = [];
unique_subjects  = STUDY.design(STUDY.currentdesign).cases.value'; % all designs have the same cases
nb_subjects      = length(unique_subjects);

% useful for multiple sessions
% nb_sets          = NaN(1,nb_subjects);
% for s = 1:nb_subjects
%     nb_sets(s) = numel(find(strcmp(unique_subjects{s},{STUDY.datasetinfo.subject})));
% end

% find out if the channels are interpolated
% -----------------------------------------
interpolated = zeros(1,length(STUDY.datasetinfo));
if strcmp(model.defaults.type,'Channels')
    for iDat = 1:length(STUDY.datasetinfo)
        fileName = fullfile(STUDY.datasetinfo(iDat).filepath, [ STUDY.datasetinfo(iDat).subject '.' opt.measure ]);
        tmpChans = load('-mat', fileName, 'labels');
        if length(tmpChans.labels) > ALLEEG(iDat).nbchan, interpolated(iDat) = 1; end
    end
end

% simply reshape to read columns
% -------------------------------------------------------------------------
order = cell(1,nb_subjects);
for s = 1:nb_subjects
    order{s} = find(strcmp(unique_subjects{s},{STUDY.datasetinfo.subject}));
end

% Cleaning old files from the current design (Cleaning ALL)
% -------------------------------------------------------------------------
% NOTE: Clean up the .lock files to (to be implemented)
% [STUDY.filepath filesep 'derivatives' filesep 'limo_batch_report']
if strcmp(opt.erase,'on')
    [tmp,filename] = fileparts(STUDY.filename);
    std_limoerase(STUDY.filepath, filename, unique_subjects, num2str(STUDY.currentdesign));
    STUDY.limo = [];
end

% Check if the measures has been computed
% -------------------------------------------------------------------------
for nsubj = 1 : nb_subjects
    inds     = find(strcmp(unique_subjects{nsubj},{STUDY.datasetinfo.subject}));

    % Checking for relative path
    study_fullpath = rel2fullpath(STUDY.filepath,STUDY.datasetinfo(inds(1)).filepath);
    %---
    subjpath = fullfile(study_fullpath, [unique_subjects{nsubj} '.' lower(Analysis)]);  % Check issue when relative path (remove comment)
    if exist(subjpath,'file') ~= 2
        error('std_limo: Measures must be computed first');
    end
end
clear study_fullpath pathtmp;

measureflags = struct('daterp','off',...
                     'datspec','off',...
                     'datersp','off',...
                     'datitc' ,'off',...
                     'icaerp' ,'off',...
                     'icaspec','off',...
                     'icaersp','off',...
                     'icaitc','off');

measureflags.(lower(opt.measureori))= 'on';
STUDY.etc.measureflags = measureflags;

% generate temporary merged datasets needed by LIMO
% -------------------------------------------------
mergedChanlocs = eeg_mergelocs(ALLEEG.chanlocs);
for s = 1:nb_subjects
    % field which are needed by LIMO
    % EEGLIMO.etc
    % EEGLIMO.times
    % EEGLIMO.chanlocs
    % EEGLIMO.srate
    % EEGLIMO.filepath
    % EEGLIMO.filename
    % EEGLIMO.icawinv
    % EEGLIMO.icaweights

    filename = [STUDY.datasetinfo(order{s}(1)).subject '_limo_file_tmp' num2str(design_index) '.set'];
    index    = [STUDY.datasetinfo(order{s}).index];
    tmp      = {STUDY.datasetinfo(order{s}).subject};
    if length(unique(tmp)) ~= 1
        error('it seems that sets of different subjects are merged')
    else
        names{s} =  cell2mat(unique(tmp));
    end

    % Creating fields for limo
    % ------------------------
    for sets = 1:length(index)
        EEGTMP = std_lm_seteegfields(STUDY,ALLEEG(index(sets)), index(sets),'datatype',model.defaults.type,'format', 'cell');
        ALLEEG = eeg_store(ALLEEG, EEGTMP, index(sets));
    end

    file_fullpath      = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).filepath);
    model.set_files{s} = fullfile(file_fullpath , filename);

    OUTEEG = [];
    if all([ALLEEG(index).trials] == 1)
         OUTEEG.trials = 1;
    else
        OUTEEG.trials = sum([ALLEEG(index).trials]);
    end

    filepath_tmp           = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).filepath);
    OUTEEG.filepath        = filepath_tmp;
    OUTEEG.filename        = filename;
    OUTEEG.srate           = ALLEEG(index(1)).srate;
    OUTEEG.icaweights      = ALLEEG(index(1)).icaweights;
    OUTEEG.icasphere       = ALLEEG(index(1)).icasphere;
    OUTEEG.icawinv         = ALLEEG(index(1)).icawinv;
    OUTEEG.icachansind     = ALLEEG(index(1)).icachansind;
    OUTEEG.etc             = ALLEEG(index(1)).etc;
    OUTEEG.times           = ALLEEG(index(1)).times;
    if any(interpolated)
        OUTEEG.chanlocs    = mergedChanlocs;
        OUTEEG.etc.interpolatedchannels = setdiff([1:length(OUTEEG.chanlocs)], std_chaninds(OUTEEG, { ALLEEG(index(1)).chanlocs.labels }));
    else
        OUTEEG.chanlocs    = ALLEEG(index(1)).chanlocs;
    end

    % update EEG.etc
    OUTEEG.etc.merged{1}   = ALLEEG(index(1)).filename;

    % Def fields
    OUTEEG.etc.datafiles.daterp   = [];
    OUTEEG.etc.datafiles.datspec  = [];
    OUTEEG.etc.datafiles.dattimef = [];
    OUTEEG.etc.datafiles.datitc   = [];
    OUTEEG.etc.datafiles.icaerp   = [];
    OUTEEG.etc.datafiles.icaspec  = [];
    OUTEEG.etc.datafiles.icatimef = [];
    OUTEEG.etc.datafiles.icaitc   = [];

    % Filling fields
    if isfield(ALLEEG(index(1)).etc, 'datafiles')
        if isfield(ALLEEG(index(1)).etc.datafiles,'daterp')
            OUTEEG.etc.datafiles.daterp{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.daterp);
        end
        if isfield(ALLEEG(index(1)).etc.datafiles,'datspec')
            OUTEEG.etc.datafiles.datspec{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.datspec);
        end
        if isfield(ALLEEG(index(1)).etc.datafiles,'dattimef')
            OUTEEG.etc.datafiles.datersp{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.dattimef);
        end
        if isfield(ALLEEG(index(1)).etc.datafiles,'datitc')
            OUTEEG.etc.datafiles.datitc{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.datitc);
        end
        if isfield(ALLEEG(index(1)).etc.datafiles,'icaerp')
            OUTEEG.etc.datafiles.icaerp{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.icaerp);
        end
        if isfield(ALLEEG(index(1)).etc.datafiles,'icaspec')
            OUTEEG.etc.datafiles.icaspec{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.icaspec);
        end
        if isfield(ALLEEG(index(1)).etc.datafiles,'icatimef')
            OUTEEG.etc.datafiles.icaersp{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.icatimef);
        end
        if isfield(ALLEEG(index(1)).etc.datafiles,'icaitc')
            OUTEEG.etc.datafiles.icaitc{1} = rel2fullpath(STUDY.filepath,ALLEEG(index(1)).etc.datafiles.icaitc);
        end
    end

%     OUTEEG.etc.freqsersp =

    % Save info
    EEG = OUTEEG;
    save('-mat', fullfile( filepath_tmp, OUTEEG.filename), 'EEG');
    clear OUTEEG filepath_tmp
end

% generate data files
% -------------------

% by default we create a design matrix with all condition
factors = pop_listfactors(STUDY.design(opt.design), 'gui', 'off');
for s = 1:nb_subjects
    % save continuous and categorical data files
    trialinfo = std_combtrialinfo(STUDY.datasetinfo, unique_subjects{s});
    [catMat,contMat,limodesign] = std_limodesign(factors, trialinfo, 'splitreg', opt.splitreg, 'interaction', opt.interaction);

    % copy results
    model.cat_files{s}                 = catMat;
    model.cont_files{s}                = contMat;
    STUDY.limo.categorical             = limodesign.categorical;
    STUDY.limo.continuous              = limodesign.continuous;
    STUDY.limo.subjects(s).subject     = unique_subjects{s};
    STUDY.limo.subjects(s).cat_file    = catMat;
    STUDY.limo.subjects(s).cont_file   = contMat;
end

% then we add contrasts for conditions that were merged during design selection
% if length(STUDY.design(opt.design).variable(1).value) ~= length(factors)
%     limocontrast = zeros(length(STUDY.design(opt.design).variable.value),length(factors)+1); % length(factors)+1 to add the contant
%     for n=1:length(factors)
%         factor_names{n} = factors(n).value;
%     end
%
%     for c=1:length(STUDY.design(opt.design).variable.value)
%         limocontrast(c,1:length(factors)) = single(ismember(factor_names,STUDY.design(opt.design).variable.value{c}));
%     end
% end

% transpose
model.set_files  = model.set_files';
model.cat_files  = model.cat_files';
model.cont_files = model.cont_files';
if all(cellfun(@isempty, model.cat_files )), model.cat_files  = []; end
if all(cellfun(@isempty, model.cont_files)), model.cont_files = []; end


% set model.defaults - all conditions no bootstrap
% -----------------------------------------------------------------
% to update passing the timing/frequency from STUDY - when computing measures
% -----------------------------------------------------------------
if strcmp(Analysis,'daterp') || strcmp(Analysis,'icaerp')
    model.defaults.analysis = 'Time';
    model.defaults.start    = ALLEEG(index(1)).xmin*1000;
    model.defaults.end      = ALLEEG(index(1)).xmax*1000;
    if length(opt.timelim) == 2 && opt.timelim(1) < opt.timelim(end)
        % start value
        if opt.timelim(1) < model.defaults.start
            fprintf('std_limo: Invalid time lower limit, using default value instead');
        else
            model.defaults.start = opt.timelim(1);
        end
        % end value
        if opt.timelim(end) > model.defaults.end
            fprintf('std_limo: Invalid time upper limit, using default value instead');
        else
            model.defaults.end = opt.timelim(end);
        end
    end

    model.defaults.lowf  = [];
    model.defaults.highf = [];

elseif strcmp(Analysis,'datspec') || strcmp(Analysis,'icaspec')

    model.defaults.analysis= 'Frequency';
    if length(opt.freqlim) == 2
        model.defaults.lowf    = opt.freqlim(1);
        model.defaults.highf   = opt.freqlim(2);
    else
        error('std_limo: Frequency limits need to be specified');
    end

elseif strcmp(Analysis,'datersp') || strcmp(Analysis,'dattimef') || strcmp(Analysis,'icaersp')
    model.defaults.analysis = 'Time-Frequency';
    model.defaults.start    = [];
    model.defaults.end      = [];
    model.defaults.lowf     = [];
    model.defaults.highf    = [];

    if length(opt.timelim) == 2
        model.defaults.start    = opt.timelim(1);
        model.defaults.end      = opt.timelim(2);
    end
    if length(opt.freqlim) == 2
        model.defaults.lowf     = opt.freqlim(1);
        model.defaults.highf    = opt.freqlim(2);
    end
end

model.defaults.fullfactorial    = 0;                 % all variables
model.defaults.zscore           = 0;                 % done that already
model.defaults.bootstrap        = 0 ;                % only for single subject analyses - not included for studies
model.defaults.tfce             = 0;                 % only for single subject analyses - not included for studies
model.defaults.method           = opt.method;        % default is OLS - to be updated to 'WLS' once validated
model.defaults.Level            = 1;                 % 1st level analysis
model.defaults.type_of_analysis = 'Mass-univariate'; % option can be multivariate (work in progress)


if ~exist('limocontrast','var')
    [LIMO_files, procstatus] = limo_batch('model specification',model,[],STUDY);
else
    contrast.mat = limocontrast;
    [LIMO_files, procstatus] = limo_batch('both',model,contrast,STUDY);
    clear contrast.mat;
    save([STUDY.filepath filesep 'derivatives' filesep STUDY.design(opt.design).name '_contrast.mat'],'limocontrast');
end

STUDY.limo.model         = model;
STUDY.limo.datatype      = Analysis;
STUDY.limo.chanloc       = limoChanlocs.expected_chanlocs;
if exist('limocontrast','var')
    STUDY.limo.contrast      = limocontrast;
end

% Save STUDY
if sum(procstatus) ~= 0
    if sum(procstatus) == nb_subjects
        STUDY = pop_savestudy( STUDY, [],'filepath', STUDY.filepath,'savemode','resave');
        cd(STUDY.filepath);
    else
        warndlg2('some subjects failed to process, check batch report')
    end
else
    errordlg2('all subjects failed to process, check batch report')
end

% cleanup temp files
for s = 1:nb_subjects
    delete(model.set_files{s});
end

%% start 2nd level


% -------------------------------------------------------------------------
% Return full path if 'filepath' is a relative path. The output format will
% fit the one of 'filepath'. That means that if 'filepath' is a cell array,
% then the output will a cell array too, and the same if is a string.
function file_fullpath = rel2fullpath(studypath,filepath)

nit = 1; if iscell(filepath), nit = length(filepath);end

for i = 1:nit
    if iscell(filepath),pathtmp = filepath{i}; else pathtmp = filepath; end
    if strfind(pathtmp(end),filesep), pathtmp = pathtmp(1:end-1); end % Getting rid of filesep at the end
    if ~isempty(strfind(pathtmp(1:2),['.' filesep])) || (isunix && pathtmp(1) ~= '/') || (ispc && pathtmp(2) ~= ':')
        if iscell(filepath),
            file_fullpath{i} = fullfile(studypath,pathtmp(1:end));
        else
            file_fullpath = fullfile(studypath,pathtmp(1:end));
        end
    else
        if iscell(filepath)
            file_fullpath{i} = pathtmp;
        else
            file_fullpath = pathtmp;
        end
    end
end
