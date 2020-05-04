function vers = eegplugin_markevents(fig, trystrs, catchstrs)
% eegplugin_markevents() - EEGLAB plugin for event marking continuos data.
%
% Usage:
%   >> eegplugin_markevents(fig, trystrs, catchstrs)
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
%   EEGLABEL, POP_EEGLABEL, EEGLAB
%
% Author: German Gomez-Herrero <german.gomezherrero@tut.fi>
%         Institute of Signal Processing
%         Tampere University of Technology, 2008
%
% Copyright (C) <2007>  German Gomez-Herrero, http://germangh.com%
%
% Modifed by Stuart Fogel to work with newer eeglab versions
% Brain & Mind Institute, Western University, Canada
% July 7, 2014

vers = '2.1';
if nargin < 3
    error('eegplugin_markevents requires 3 arguments');
end

% add plugin folder to path
% -----------------------
if exist('pop_eeglabel.m','file')
    p = which('eegplugin_markevents');
    p = p(1:findstr(p,'eegplugin_markevents.m')-1);
    addpath(p);    
end

% find tools menu
% ---------------------
menu = findobj(fig, 'tag', 'tools');

% menu callbacks
% --------------
eeglabel_cback = [ trystrs.no_check '[LASTCOM] = pop_eeglabel(EEG);' catchstrs.add_to_hist ];

% create menus if necessary
% -------------------------
submenu = uimenu( menu, 'Label', 'Mark Events');
uimenu( submenu, 'Label', 'Mark Events', 'CallBack', eeglabel_cback);