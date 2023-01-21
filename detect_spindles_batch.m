function [ALLEEG] = detect_spindles_batch()

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
% Build EEG structure from multiple EEG datasets to batch run detect_spindles
%
% Contact:  sfogel@uottawa.ca
%
% Date:     May 6, 2020
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
% This file is part of 'detect_spindles'.
% See https://github.com/stuartfogel/detect_REMS for details.
%

% Copyright (C) Stuart Fogel & Sleep Well, 2022.
% https://socialsciences.uottawa.ca/sleep-lab/
% https://www.sleepwellpsg.com
%
% See the GNU General Public License v3.0 for more information.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
%
% 1. Redistributions of source code must retain the above author, license,
% copyright notice, this list of conditions, and the following disclaimer.
%
% 2. Redistributions in binary form must reproduce the above author, license,
% copyright notice, this list of conditions, and the following disclaimer in
% the documentation and/or other materials provided with the distribution.
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
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% LOAD EEGLAB
if ~isempty(which('eeglab'))
    eeglab nogui
    clear
else
    try
        dirName = dirNames(startsWith({dirNames([dirNames.isdir]).name}, 'eeglab20')).folder;
        folderName = dirNames(startsWith({dirNames([dirNames.isdir]).name}, 'eeglab20')).name;
        if isempty('dirName')
            errordlg('Please add EEGLAB main folder to Matlab path.','EEGLAB not found')
            return
        end
        addpath([dirName filesep folderName]);
    catch
        errordlg('Please add EEGLAB main folder to Matlab path.','EEGLAB not found')
        return
    end
end

%% SPECIFY FILENAMES (OPTIONAL)
% you can manually specify filenames here, or leave empty for pop-up
pathname = '';
filename = {'',...
    ''
    };

%% MANUALLY SELECT *.SET FILES
if isempty(pathname)
    [filename, pathname] = uigetfile( ...
        {'*.set','EEGlab Dataset (*.set)'; ...
        '*.mat','MAT-files (*.mat)'; ...
        '*.*',  'All Files (*.*)'}, ...
        'multiselect', 'on');
end
% check the filename(s)
if isequal(filename,0) || isequal(pathname,0) % no files were selected
    disp('User selected Cancel')
    return;
else
    if ischar(filename) % Only one file was selected. That's odd. Why would you use this script?
        error('Only one dataset selected. Batch mode is for multiple datasets.')
    end
end

%% BUILD EEG BATCH AND LAUNCH SPINDLE DETECTION
for nfile = 1:length(filename)
    EEG = pop_loadset('filename',filename{1,nfile},'filepath',pathname);
    ALLEEG(nfile) = EEG;
end
ALLEEG = pop_detect_spindles(ALLEEG);

end