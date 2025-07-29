%% Manual Connect
% Atkin Hyatt 07/22/2024
%
% Last revised by Atkin Hyatt on 07/22/2024
%
% In case LiveLink doesn't work for any reason. Allows the user to start
% and connect to a COMSOL server inside of MATLAB. To manually connect,
% copy and paste the COMSOL mli filepath into line 16 and press run.
% The file we want is named 'mli' and usually lives in the COMSOL
% application folder.

% Start COMSOL server
%system('/Applications/COMSOL54/Multiphysics/bin/comsol mphserver -port 2036');

% Find COMSOL server location and add to MATLAB filepath (paste mli filepath here)
addpath('/Applications/COMSOL54/Multiphysics/mli');

% Establish server connection and gain access to all LiveLink commands
mphstart;
import com.comsol.model.util.*