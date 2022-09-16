function vers = eegplugin_detect_spindles(fig, trystrs, catchstrs)

% eegplugin_detect_spindles() - EEGLAB plugin for sleep spindle detection
%
% Usage:
%   >> eegplugin_detect_spindles(fig, trystrs, catchstrs)
%
% Inputs:
%   fig        - [integer] EEGLAB figure.
%   trystrs    - [struct] "try" strings for menu callbacks.
%   catchstrs  - [struct] "catch" strings for menu callbacks. 
%
% Create a plugin:
%   For more information on how to create an EEGLAB plugin see the
%   help message of eegplugin_besa() or visit http://www.sccn.ucsd.edu/eeglab/contrib.html
%
% See also:
%   detect_spindles, pop_detect_spindles, eeglab
%
% Author: 
%   Stuart Fogel <sfogel@uottawa.ca>
%   School of Psychology
%   University of Ottawa
%
% Copyright (C) <2020>  Stuart Fogel, http://socialsciences.uottawa.ca/sleep-lab/
%

vers = '2.8.1';
if nargin < 3
    error('eegplugin_detect_spindles requires 3 arguments');
end

% add plugin folder to path
% -----------------------
if exist('pop_detect_spindles.m','file')
    p = which('eegplugin_detect_spindles');
    p = p(1:findstr(p,'eegplugin_detect_spindles.m')-1);
    addpath(p);
    addpath([p 'src/'])
end

% find tools menu
% ---------------------
menu = findobj(fig, 'tag', 'tools');

% menu callbacks
% --------------
detect_spindle_cback = [ trystrs.no_check '[EEG,LASTCOM] = pop_detect_spindles(EEG);[ALLEEG EEG CURRENTSET] = pop_newset(ALLEEG, EEG, CURRENTSET);eeglab redraw;' catchstrs.add_to_hist ];

% create menus if necessary
% -------------------------
submenu = uimenu( menu, 'Label', 'Detect Spindles');
uimenu( submenu, 'Label', 'Detect Spindles', 'CallBack', detect_spindle_cback);