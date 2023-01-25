
function varargout = headfix_OPERANT_GUI_BOX2(varargin)
% HEADFIX_OPERANT_GUI_BOX2 MATLAB code for headfix_OPERANT_GUI_BOX2.fig
%      HEADFIX_OPERANT_GUI_BOX2, by itself, creates a new HEADFIX_OPERANT_GUI_BOX2 or raises the existing
%      singleton*.
%
%      H = HEADFIX_OPERANT_GUI_BOX2 returns the handle to a new HEADFIX_OPERANT_GUI_BOX2 or the handle to
%      the existing singleton*.
%
%      HEADFIX_OPERANT_GUI_BOX2('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in HEADFIX_OPERANT_GUI_BOX2.M with the given input arguments.
%
%      HEADFIX_OPERANT_GUI_BOX2('Property','Value',...) creates a new HEADFIX_OPERANT_GUI_BOX2 or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before headfix_OPERANT_GUI_BOX2_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to headfix_OPERANT_GUI_BOX2_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help headfix_OPERANT_GUI_BOX2

% Last Modified by GUIDE v2.5 26-Jul-2019 15:39:33

% cd 'F:\acads\Stuber lab\headfix'; %Change to directory

% MAY 2017 MODIFICATION: LASER CONTROL TO BE USED WITH ITP_OPERANT_V3
% ARDUINO CODE

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @headfix_OPERANT_GUI_BOX2_OpeningFcn, ...
                   'gui_OutputFcn',  @headfix_OPERANT_GUI_BOX2_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT

% --- Executes just before headfix_OPERANT_GUI_BOX2 is made visible.
function headfix_OPERANT_GUI_BOX2_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to headfix_OPERANT_GUI_BOX2 (see VARARGIN)

% Choose default command line output for headfix_OPERANT_GUI_BOX2
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);


% This sets up the initial plot - only do when we are invisible
% so window can get raised using headfix_OPERANT_GUI_BOX2.
% if strcmp(get(hObject,'Visible'),'off')
%     plot(rand(5));
% end

global actvAx saveDir

mainPath = 'C:\Users\Otis Lab\Documents\MATLAB';
addpath(mainPath)
saveDir = [mainPath '/K_Box2_Data/'];          % where to save data

actvAx  = handles.activityAxes;         % handle for activity plot

% Find available serial ports
serialInfo = instrhwinfo('serial');
port = serialInfo.AvailableSerialPorts;
if ~isempty(port)
    set(handles.availablePorts,'String',port)
end

% Change window title
set(gcf,'name','Head-fixed behavior')

% UIWAIT makes headfix_OPERANT_GUI_BOX2 wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = headfix_OPERANT_GUI_BOX2_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;


% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function prefs_Callback(hObject, eventdata, handles)
% hObject    handle to prefs (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --------------------------------------------------------------------
function CloseMenuItem_Callback(hObject, eventdata, handles)
% hObject    handle to CloseMenuItem (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
selection = questdlg(['Close ' get(handles.figure1,'Name') '?'],...
                     ['Close ' get(handles.figure1,'Name') '...'],...
                     'Yes','No','Yes');
if strcmp(selection,'No')
    return;
end

delete(handles.figure1)


% --- Executes during object deletion, before destroying properties.
function figure1_DeleteFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

instrreset
if exist('s','var')
    fclose(s)
end


% --- Executes on button press in refreshButton.
function refreshButton_Callback(hObject, eventdata, handles)
% hObject    handle to refreshButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

serialInfo = instrhwinfo('serial');                             % get info on connected serial ports
port = serialInfo.AvailableSerialPorts;                         % get names of ports
if ~isempty(port)
    set(handles.availablePorts,'String',port)                   % update list of ports available
else
    set(handles.availablePorts,'String', ...
        'none found, please check connection and refresh')      % if none, indicate so
end

% --- Executes on button press in openButton.
function openButton_Callback(hObject, eventdata, handles)
% opens serial port (identified by user) for communication with arduino

global s

portList = get(handles.availablePorts,'String');    % get list from popup menu
selected = get(handles.availablePorts,'Value');     % find which is selected
port     = portList{selected};                      % selected port

s = serial(port,'BaudRate',9600,'Timeout',1);    % setup serial port with arduino, specify the terminator as a LF ('\n' in Arduino)
fopen(s)                                            % open serial port with arduino
% get(s)
set(handles.openButton,'String','Wait 5s');
pause(5);
set(handles.openButton,'String','Link');

set(handles.port,'String',port)                     % write out port selected in menu
set(handles.sendButton,'Enable','on')               % enable 'send' button
set(handles.startButton,'Enable','off')             % disable 'send' button
set(handles.closeButton,'Enable','on')              % enable 'unlink' button
set(handles.openButton,'Enable','off')              % disable 'link' button
set(handles.refreshButton,'Enable','off')           % disable 'refresh' button


% --- Executes on button press in closeButton.
function closeButton_Callback(hObject, eventdata, handles)

global s
fclose(s)
instrreset                                          % "closes serial"
set(handles.port,'String','port not selected')      % remove port from menu
set(handles.startButton,'Enable','off')             % turn off 'start' button
set(handles.closeButton,'Enable','off')             % turn off 'unlink' button (self)
set(handles.openButton,'Enable','on')               % turn on 'link' button
set(handles.refreshButton,'Enable','on')            % turn on 'refresh' button


% --- Executes on button press in startButton.
 
function startButton_Callback(hObject, eventdata, handles)

global s running actvAx saveDir

% Retrieve inputs
T_bgd = get(handles.T_bgd,'String');
r_bgd = get(handles.r_bgd,'String');
t_fxd = get(handles.t_fxd,'String');
r_fxd = get(handles.r_fxd,'String');
minITI = get(handles.minITI,'String');
maxITI = get(handles.maxITI,'String');
cuedur = get(handles.cuedur,'String');
sessionLim = get(handles.sessionLim,'String');
mindelaybgdtocue = get(handles.mindelaybgdtocue,'String');
mindelayfxdtobgd = get(handles.mindelayfxdtobgd,'String');
numCSminus = get(handles.numCSminus,'String');
CSplusfreq = get(handles.CSplusfreq,'String');
CSminusfreq = get(handles.CSminusfreq,'String');
nocuesflag = get(handles.checkboxnocues,'Value');
trialbytrialbgdpumpflag = get(handles.checkboxtrialbytrial,'Value');
expitiflag = get(handles.checkboxexpiti,'Value');
laserlatency = get(handles.laserlatency,'String');
laserduration = get(handles.laserduration,'String');
randlaserflag = get(handles.checkboxrandlaser,'Value');
laserpulseperiod = get(handles.laserpulseperiod,'String');
laserpulseoffperiod = get(handles.laserpulseoffperiod,'String');
totPoissrew = get(handles.totPoissrew,'String'); % Total Poisson rewards to deliver
lasertrialbytrialflag = get(handles.lasertrialbytrial,'Value');
differentspeakerflag = get(handles.differentspeaker,'Value');
csplusprob = get(handles.csplusprob,'String');
csminusprob = get(handles.csminusprob,'String');
% retrive operant conditioning inputs. Added by ITP
OperantExperiment = get(handles.onOff_OC_checkbox, 'Value');
leftActive = get(handles.left_active_OC_checkbox, 'Value');
rightActive = get(handles.right_active_OC_checkbox, 'Value');
leftPT = get(handles.left_PT_OC_popupmenu, 'Value');
rightPT = get(handles.right_PT_OC_popupmenu, 'Value');
leftRecInc = get(handles.left_RnumInc_OC_text, 'String');
rightRecInc = get (handles.Right_RnumInc_OC_text, 'String');
leftRWmag = get (handles.leftREWmag,'String');
rightRWmag = get(handles.rightREWmag, 'String');
trialNumLim = get(handles.trialNumLim, 'String');
trialTimeLimit = get(handles.trialTimeLimit, 'String');
n1 = get(handles.edit59,'String');
n1 = str2double(n1);
t = timer('TimerFcn','state=false;[], n1=0 ', 'StartDelay',n1);
start(t) 
state=true;

if (state==true) 
    for i=1,(n1-i);
        fprintf ('%d/n1',i);
        
        pause(1)
    end
    if (1>n1)gui 
        state=false; 
     
    end 
end
 

 if trialbytrialbgdpumpflag
    sessionLim = '120';%Hard set total number of trials to 120 if background rewards are changing on a trial by trial 
    %basis. This is because there are 4 different reward rates being
    %tested. So every odd trial has one of these rates randomly chosen and
    %every even trial has a background rate of zero
    numCSminus = '60';%Hard set number of CS- trials to 60
    set(handles.sessionLim,'String','120');
    set(handles.numCSminus,'String','60');
end


T_bgd = str2double(T_bgd);
r_bgd = str2double(r_bgd);
t_fxd = str2double(t_fxd);
r_fxd = str2double(r_fxd);
minITI = str2double(minITI);
maxITI = str2double(maxITI);
cuedur = str2double(cuedur);
sessionLim = str2double(sessionLim);
mindelaybgdtocue = str2double(mindelaybgdtocue);
mindelayfxdtobgd = str2double(mindelayfxdtobgd);
numCSminus = str2double(numCSminus);
CSplusfreq = str2double(CSplusfreq);
CSminusfreq = str2double(CSminusfreq);
laserpulseperiod = str2double(laserpulseperiod);
laserpulseoffperiod = str2double(laserpulseoffperiod);
totPoissrew = str2double(totPoissrew);
lasertrialbytrialflag = str2double(lasertrialbytrialflag);
csplusprob = str2double(csplusprob);
csminusprob = str2double(csminusprob);
% Added by ITP for opperant conditioning, Nov 2016
leftPT = str2double(leftPT);
rightPT = str2double(rightPT);
leftRecInc = str2double(leftRecInc);
rightRecInc = str2double(rightRecInc);
leftRWmag = str2double(leftRWmag);
rightRWmag = str2double(rightRWmag);
trialNumLim = str2double(trialNumLim);
trialTimeLimit = str2double(trialTimeLimit);


set(handles.licksEdit,'String','0')
set(handles.cuesEdit,'String','0')
set(handles.cuesminusEdit,'String','0')
set(handles.bgdpumpsEdit,'String','0')
set(handles.fxdpumpsEdit,'String','0')
set(handles.primesolenoid,'Visible','off')
%added by ITP for OC, NOV 2016
set(handles.TrialNum, 'String', '1')
set(handles.trialPressLeft, 'String', '0')
set(handles.trailPressRight, 'String', '0')
set(handles.CTrialTime, 'String', '0')

% disable/enable certain options
set(handles.startButton,'Enable','off')
set(handles.stopButton,'Enable','on')
set(handles.closeButton,'Enable','off')
set(handles.sendButton,'Enable','off')
set(handles.testcsplus,'Enable','off')
set(handles.testcsminus,'Enable','off')
set(handles.testlaser,'Enable','off')
set(handles.closeButton,'Enable','off')

%%


fname = get(handles.fileName,'String');

params = sprintf('%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+', ...
                 T_bgd,r_bgd,t_fxd,r_fxd,minITI,maxITI,cuedur,sessionLim,mindelaybgdtocue,mindelayfxdtobgd,...
                 numCSminus,CSplusfreq,CSminusfreq,nocuesflag,trialbytrialbgdpumpflag,...
                 expitiflag,laserlatency,laserduration,laserpulseperiod,...
                 laserpulseoffperiod,totPoissrew,lasertrialbytrialflag,csplusprob,csminusprob,randlaserflag,differentspeakerflag,...
                 OperantExperiment,leftActive,rightActive,leftPT,rightPT,leftRecInc,rightRecInc,leftRWmag,rightRWmag,trialNumLim,trialTimeLimit, n1)
                       

% Run arduino code

        fprintf(s,'5');                          % Signals to Arduino to start the experiment
conditioning_prog2
   

% Reset GUI
set(handles.startButton,'Enable','off')
set(handles.stopButton,'Enable','off')
set(handles.closeButton,'Enable','on')
set(handles.sendButton,'Enable','on')
set(handles.T_bgd,'Enable','on')
set(handles.r_bgd,'Enable','on')
set(handles.t_fxd,'Enable','on')
set(handles.r_fxd,'Enable','on')
set(handles.minITI,'Enable','on')
set(handles.maxITI,'Enable','on')
set(handles.cuedur,'Enable','on')
set(handles.sessionLim,'Enable','on')
set(handles.mindelaybgdtocue,'Enable','on')
set(handles.mindelayfxdtobgd,'Enable','on')
set(handles.numCSminus,'Enable','on')
set(handles.CSplusfreq,'Enable','on')
set(handles.CSminusfreq,'Enable','on')
set(handles.checkboxnocues,'Enable','on')
set(handles.checkboxtrialbytrial,'Enable','on')
set(handles.checkboxexpiti,'Enable','on')
set(handles.laserlatency,'Enable','on')
set(handles.laserduration,'Enable','on')
set(handles.checkboxrandlaser,'Enable','on')
set(handles.differentspeaker,'Enable','on')
set(handles.laserpulseperiod,'Enable','on')
set(handles.laserpulseoffperiod,'Enable','on')
set(handles.testcsplus,'Enable','off')
set(handles.testcsminus,'Enable','off')
set(handles.testlaser,'Enable','off')
set(handles.totPoissrew,'Enable','on');
set(handles.pumpButton,'Enable','off');
set(handles.primesolenoid,'Visible','off');
set(handles.lasertrialbytrial,'Enable','on');
set(handles.csplusprob,'Enable','on');
set(handles.csminusprob,'Enable','on');
%% added by ITP for OC, Nov 2016
set (handles.onOff_OC_checkbox, 'Enable', 'off');
set (handles.left_active_OC_checkbox, 'Enable', 'off');
set(handles.right_active_OC_checkbox, 'Enable', 'off');
set(handles.left_PT_OC_popupmenu, 'Enable', 'off');
set(handles.right_PT_OC_popupmenu, 'Enable', 'off');
set(handles.left_RnumInc_OC_text, 'Enable', 'off');
set(handles.Right_RnumInc_OC_text, 'Enable', 'off');
set (handles.leftREWmag,'Enable', 'off');
set(handles.rightREWmag, 'Enable', 'off');
set(handles.trialNumLim, 'Enable', 'off');
set(handles.trialTimeLimit, 'Enable', 'off');

flushinput(s);                                  % clear serial input buffer

% --- Executes on button press in stopButton.
function stopButton_Callback(hObject, eventdata, handles)

global s running
running = false;            % Stop running MATLAB code for monitoring arduino
fprintf(s,'1');              % Send stop signal to arduino; 49 in the Arduino is the ASCII code for 1


% --- Executes on button press in pumpButton.
function pumpButton_Callback(hObject, eventdata, handles)

global s
fprintf(s,'2');              % Send pump signal to arduino; 50 in the Arduino is the ASCII code for 2


function T_bgd_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function T_bgd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to T_bgd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function r_bgd_Callback(hObject, eventdata, handles)
% hObject    handle to r_bgd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of r_bgd as text
%        str2double(get(hObject,'String')) returns contents of r_bgd as a double


% --- Executes during object creation, after setting all properties.
function r_bgd_CreateFcn(hObject, ~, handles)
% hObject    handle to r_bgd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function t_fxd_Callback(hObject, eventdata, handles)
% hObject    handle to t_fxd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of t_fxd as text
%        str2double(get(hObject,'String')) returns contents of t_fxd as a double


% --- Executes during object creation, after setting all properties.
function t_fxd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to t_fxd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function r_fxd_Callback(hObject, eventdata, handles)
% hObject    handle to r_fxd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of r_fxd as text
%        str2double(get(hObject,'String')) returns contents of r_fxd as a double


% --- Executes during object creation, after setting all properties.
function r_fxd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to r_fxd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function minITI_Callback(hObject, eventdata, handles)
% hObject    handle to minITI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of minITI as text
%        str2double(get(hObject,'String')) returns contents of minITI as a double


% --- Executes during object creation, after setting all properties.
function minITI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to minITI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function maxITI_Callback(hObject, eventdata, handles)
% hObject    handle to maxITI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of maxITI as text
%        str2double(get(hObject,'String')) returns contents of maxITI as a double


% --- Executes during object creation, after setting all properties.
function maxITI_CreateFcn(hObject, eventdata, handles)
% hObject    handle to maxITI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cuedur_Callback(hObject, eventdata, handles)
% hObject    handle to cuedur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cuedur as text
%        str2double(get(hObject,'String')) returns contents of cuedur as a double


% --- Executes during object creation, after setting all properties.
function cuedur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cuedur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function sessionLim_Callback(hObject, eventdata, handles)
% hObject    handle to sessionLim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of sessionLim as text
%        str2double(get(hObject,'String')) returns contents of sessionLim as a double


% --- Executes during object creation, after setting all properties.
function sessionLim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to sessionLim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function mindelaybgdtocue_Callback(hObject, eventdata, handles)
% hObject    handle to mindelaybgdtocue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mindelaybgdtocue as text
%        str2double(get(hObject,'String')) returns contents of mindelaybgdtocue as a double


% --- Executes during object creation, after setting all properties.
function mindelaybgdtocue_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mindelaybgdtocue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function mindelayfxdtobgd_Callback(hObject, eventdata, handles)
% hObject    handle to mindelayfxdtobgd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of mindelayfxdtobgd as text
%        str2double(get(hObject,'String')) returns contents of mindelayfxdtobgd as a double


% --- Executes during object creation, after setting all properties.
function mindelayfxdtobgd_CreateFcn(hObject, eventdata, handles)
% hObject    handle to mindelayfxdtobgd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in availablePorts.
function availablePorts_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function availablePorts_CreateFcn(hObject, eventdata, handles)
% hObject    handle to availablePorts (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function port_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function port_CreateFcn(hObject, eventdata, handles)
% hObject    handle to port (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


function fileName_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function fileName_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fileName (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function licksEdit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function licksEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to licksEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cuesEdit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function cuesEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cuesEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function timeEdit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function timeEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to timeEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function pumpDur_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function pumpDur_CreateFcn(hObject, eventdata, handles)
% hObject    handle to pumpDur (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function startText_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function startText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to startText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rewardsEdit_Callback(hObject, eventdata, handles)

% --- Executes during object creation, after setting all properties.
function rewardsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rewardsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function bgdpumpsEdit_Callback(hObject, eventdata, handles)
% hObject    handle to bgdpumpsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of bgdpumpsEdit as text
%        str2double(get(hObject,'String')) returns contents of bgdpumpsEdit as a double


% --- Executes during object creation, after setting all properties.
function bgdpumpsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to bgdpumpsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function fxdpumpsEdit_Callback(hObject, eventdata, handles)
% hObject    handle to fxdpumpsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of fxdpumpsEdit as text
%        str2double(get(hObject,'String')) returns contents of fxdpumpsEdit as a double


% --- Executes during object creation, after setting all properties.
function fxdpumpsEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to fxdpumpsEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function cuesminusEdit_Callback(hObject, eventdata, handles)
% hObject    handle to cuesminusEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of cuesminusEdit as text
%        str2double(get(hObject,'String')) returns contents of cuesminusEdit as a double


% --- Executes during object creation, after setting all properties.
function cuesminusEdit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to cuesminusEdit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function numCSminus_Callback(hObject, eventdata, handles)
% hObject    handle to numCSminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of numCSminus as text
%        str2double(get(hObject,'String')) returns contents of numCSminus as a double


% --- Executes during object creation, after setting all properties.
function numCSminus_CreateFcn(hObject, eventdata, handles)
% hObject    handle to numCSminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CSplusfreq_Callback(hObject, eventdata, handles)
% hObject    handle to CSplusfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CSplusfreq as text
%        str2double(get(hObject,'String')) returns contents of CSplusfreq as a double


% --- Executes during object creation, after setting all properties.
function CSplusfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CSplusfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function CSminusfreq_Callback(hObject, eventdata, handles)
% hObject    handle to CSminusfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CSminusfreq as text
%        str2double(get(hObject,'String')) returns contents of CSminusfreq as a double


% --- Executes during object creation, after setting all properties.
function CSminusfreq_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CSminusfreq (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in testcsplus.
function testcsplus_Callback(hObject, eventdata, handles)
% hObject    handle to testcsplus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s
fprintf(s,'3');              % Send pump signal to arduino; 51 in the Arduino is the ASCII code for 3
flushinput(s)


% --- Executes on button press in testcsminus.
function testcsminus_Callback(hObject, eventdata, handles)
% hObject    handle to testcsminus (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s
fprintf(s,'4');              % Send pump signal to arduino; 52 in the Arduino is the ASCII code for 4
flushinput(s)

% --- Executes on button press in checkboxnocues.
function checkboxnocues_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxnocues (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxnocues


% --- Executes on button press in sendButton.
function sendButton_Callback(hObject, eventdata, handles)
% hObject    handle to sendButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s;

% Retrieve inputs
T_bgd = get(handles.T_bgd,'String');
r_bgd = get(handles.r_bgd,'String');
t_fxd = get(handles.t_fxd,'String');
r_fxd = get(handles.r_fxd,'String');
minITI = get(handles.minITI,'String');
maxITI = get(handles.maxITI,'String');
cuedur = get(handles.cuedur,'String');
sessionLim = get(handles.sessionLim,'String');
mindelaybgdtocue = get(handles.mindelaybgdtocue,'String');
mindelayfxdtobgd = get(handles.mindelayfxdtobgd,'String');
numCSminus = get(handles.numCSminus,'String');
CSplusfreq = get(handles.CSplusfreq,'String');
CSminusfreq = get(handles.CSminusfreq,'String');
nocuesflag = get(handles.checkboxnocues,'Value');
trialbytrialbgdpumpflag = get(handles.checkboxtrialbytrial,'Value');
expitiflag = get(handles.checkboxexpiti,'Value');
laserlatency = get(handles.laserlatency,'String');
laserduration = get(handles.laserduration,'String');
randlaserflag = get(handles.checkboxrandlaser,'Value');
laserpulseperiod = get(handles.laserpulseperiod,'String');
laserpulseoffperiod = get(handles.laserpulseoffperiod,'String');
totPoissrew = get(handles.totPoissrew,'String'); % Total Poisson rewards to deliver
lasertrialbytrialflag = get(handles.lasertrialbytrial,'Value');
differentspeakerflag = get(handles.differentspeaker,'Value');
%CS+ and CS- probability added on 12/7/2015
csplusprob = get(handles.csplusprob,'String');
csminusprob = get(handles.csminusprob,'String');
% retrive operant conditioning inputs. Added by ITP Nov 2016
OperantExperiment = get(handles.onOff_OC_checkbox, 'Value');
leftActive = get(handles.left_active_OC_checkbox, 'Value');
rightActive = get(handles.right_active_OC_checkbox, 'Value');
leftPT = get(handles.left_PT_OC_popupmenu, 'Value');
rightPT = get(handles.right_PT_OC_popupmenu, 'Value');
leftRecInc = get(handles.left_RnumInc_OC_text, 'String');
rightRecInc = get (handles.Right_RnumInc_OC_text, 'String');
leftRWmag = get (handles.leftREWmag,'String');
rightRWmag = get(handles.rightREWmag, 'String');
trialNumLim = get(handles.trialNumLim, 'String');
trialTimeLimit = get(handles.trialTimeLimit, 'String');
n1 = get(handles.edit59,'String');
 %ADD LASERLATENCY AND LASERDURATION AS 'STRING', REPLACING LASERREWARD
 %FLAG AND LASERCUEFLAG.

if trialbytrialbgdpumpflag
    sessionLim = '120';%Hard set total number of trials to 120 if background rewards are changing on a trial by trial 
    %basis. This is because there are 4 different reward rates being
    %tested. So every odd trial has one of these rates randomly chosen and
    %every even trial has a background rate of zero
    numCSminus = '60';%Hard set number of CS- trials to 60
    set(handles.sessionLim,'String','120');
    set(handles.numCSminus,'String','60');
end

n1 = str2double(n1);
T_bgd = str2double(T_bgd);
r_bgd = str2double(r_bgd);
t_fxd = str2double(t_fxd);
r_fxd = str2double(r_fxd);
minITI = str2double(minITI);
maxITI = str2double(maxITI);
cuedur = str2double(cuedur);
sessionLim = str2double(sessionLim);
mindelaybgdtocue = str2double(mindelaybgdtocue);
mindelayfxdtobgd = str2double(mindelayfxdtobgd);
numCSminus = str2double(numCSminus);
CSplusfreq = str2double(CSplusfreq);
CSminusfreq = str2double(CSminusfreq);
laserpulseperiod = str2double(laserpulseperiod);
laserpulseoffperiod = str2double(laserpulseoffperiod);
totPoissrew = str2double(totPoissrew);
csplusprob = str2double(csplusprob);
csminusprob = str2double(csminusprob);
% Added by ITP for opperant conditioning
leftRecInc = str2double(leftRecInc);
rightRecInc = str2double(rightRecInc);
leftRWmag = str2double(leftRWmag);
rightRWmag = str2double(rightRWmag);
trialNumLim = str2double(trialNumLim);
trialTimeLimit = str2double(trialTimeLimit);
% Added by ITP to support laser control May 2017
laserlatency = str2double(laserlatency);
laserduration = str2double(laserduration); 





% Validate inputs
inputs = [T_bgd r_bgd t_fxd r_fxd minITI maxITI cuedur sessionLim mindelaybgdtocue...
    mindelayfxdtobgd numCSminus CSplusfreq CSminusfreq nocuesflag trialbytrialbgdpumpflag...
     expitiflag laserlatency laserduration laserpulseperiod laserpulseoffperiod totPoissrew...
     lasertrialbytrialflag csplusprob csminusprob randlaserflag differentspeakerflag...
     OperantExperiment leftActive rightActive leftPT rightPT leftRecInc rightRecInc leftRWmag rightRWmag trialNumLim trialTimeLimit n1]; % collect all inputs into array
 negIn  = inputs < 0;
intIn  = inputs - fix(inputs);


if any([negIn intIn])
    errordlg('Invalid inputs')
    error('Invalid inputs')
end
% if lasercueflag+laserrewardflag+randlaserflag>1
%     error('Inconsistent laser activations requested. Only select one!');
% end


% disable/enable certain options
set(handles.startButton,'Enable','on')
set(handles.sendButton,'Enable','off')
set(handles.T_bgd,'Enable','off')
set(handles.r_bgd,'Enable','off')
set(handles.t_fxd,'Enable','off')
set(handles.r_fxd,'Enable','off')
set(handles.minITI,'Enable','off')
set(handles.maxITI,'Enable','off')
set(handles.cuedur,'Enable','off')
set(handles.sessionLim,'Enable','off')
set(handles.mindelaybgdtocue,'Enable','off')
set(handles.mindelayfxdtobgd,'Enable','off')
set(handles.numCSminus,'Enable','off')
set(handles.CSplusfreq,'Enable','off')
set(handles.CSminusfreq,'Enable','off')
set(handles.checkboxnocues,'Enable','off')
set(handles.checkboxtrialbytrial,'Enable','off')
set(handles.checkboxexpiti,'Enable','off')
set(handles.laserlatency,'Enable','off')
set(handles.laserduration,'Enable','off')
set(handles.checkboxrandlaser,'Enable','off')
set(handles.differentspeaker,'Enable','off')
set(handles.laserpulseperiod,'Enable','off')
set(handles.laserpulseoffperiod,'Enable','off')
set(handles.lasertrialbytrial,'Enable','off')
set(handles.totPoissrew,'Enable','off')
set(handles.csplusprob,'Enable','off')
set(handles.csminusprob,'Enable','off')
set(handles.testcsplus,'Enable','on')
set(handles.testcsminus,'Enable','on')
set(handles.testlaser,'Enable','on')
set(handles.pumpButton,'Enable','on')
set(handles.primesolenoid,'Visible','on')



params = sprintf('%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+%u+', ...
                 T_bgd,r_bgd,t_fxd,r_fxd,minITI,maxITI,cuedur,sessionLim,mindelaybgdtocue,mindelayfxdtobgd,...
                 numCSminus,CSplusfreq,CSminusfreq,nocuesflag,trialbytrialbgdpumpflag,...
                 expitiflag,laserlatency,laserduration,laserpulseperiod,...
                 laserpulseoffperiod,totPoissrew,lasertrialbytrialflag,csplusprob,csminusprob,randlaserflag,differentspeakerflag,...
                 OperantExperiment,leftActive,rightActive,leftPT,rightPT,leftRecInc,rightRecInc,leftRWmag,rightRWmag,trialNumLim,trialTimeLimit, n1)

% Run arduino code
fprintf(s,params);                                  % send info to arduino
flushinput(s)


% --- Executes on button press in primesolenoid.
function primesolenoid_Callback(hObject, eventdata, handles)
% hObject    handle to primesolenoid (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of primesolenoid
global s

if get(hObject,'Value') == get(hObject,'Max')
    fprintf(s,'6');              % Send prime solenoid signal to arduino; 54 in the Arduino is the ASCII code for 6
else
    fprintf(s,'7');              % Send stop solenoid signal to arduino; 55 in the Arduino is the ASCII code for 7
end


% --- Executes on button press in checkboxtrialbytrial.
function checkboxtrialbytrial_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxtrialbytrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxtrialbytrial


% --- Executes on button press in checkboxlasercue.
function checkboxlasercue_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxlasercue (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxlasercue


% --- Executes on button press in checkboxlaserreward.
function checkboxlaserreward_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxlaserreward (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxlaserreward


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


% --- Executes on button press in checkboxexpiti.
function checkboxexpiti_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxexpiti (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxexpiti



function laserpulseperiod_Callback(hObject, eventdata, handles)
% hObject    handle to laserpulseperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of laserpulseperiod as text
%        str2double(get(hObject,'String')) returns contents of laserpulseperiod as a double


% --- Executes during object creation, after setting all properties.
function laserpulseperiod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to laserpulseperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function laserpulseoffperiod_Callback(hObject, eventdata, handles)
% hObject    handle to laserpulseoffperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of laserpulseoffperiod as text
%        str2double(get(hObject,'String')) returns contents of laserpulseoffperiod as a double


% --- Executes during object creation, after setting all properties.
function laserpulseoffperiod_CreateFcn(hObject, eventdata, handles)
% hObject    handle to laserpulseoffperiod (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in testlaser.
function testlaser_Callback(hObject, eventdata, handles)
% hObject    handle to testlaser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
global s
fprintf(s,'8');              % Send pump signal to arduino; 56 in the Arduino is the ASCII code for 8
flushinput(s)



function totPoissrew_Callback(hObject, eventdata, handles)
% hObject    handle to totPoissrew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of totPoissrew as text
%        str2double(get(hObject,'String')) returns contents of totPoissrew as a double


% --- Executes during object creation, after setting all properties.
function totPoissrew_CreateFcn(hObject, eventdata, handles)
% hObject    handle to totPoissrew (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in lasertrialbytrial.
function lasertrialbytrial_Callback(hObject, eventdata, handles)
% hObject    handle to lasertrialbytrial (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of lasertrialbytrial



function csplusprob_Callback(hObject, eventdata, handles)
% hObject    handle to csplusprob (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of csplusprob as text
%        str2double(get(hObject,'String')) returns contents of csplusprob as a double


% --- Executes during object creation, after setting all properties.
function csplusprob_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csplusprob (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function csminusprob_Callback(hObject, eventdata, handles)
% hObject    handle to csminusprob (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of csminusprob as text
%        str2double(get(hObject,'String')) returns contents of csminusprob as a double


% --- Executes during object creation, after setting all properties.
function csminusprob_CreateFcn(hObject, eventdata, handles)
% hObject    handle to csminusprob (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in checkboxrandlaser.
function checkboxrandlaser_Callback(hObject, eventdata, handles)
% hObject    handle to checkboxrandlaser (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of checkboxrandlaser


% --- Executes on button press in differentspeaker.
function differentspeaker_Callback(hObject, eventdata, handles)
% hObject    handle to differentspeaker (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of differentspeaker


% --- Executes on selection change in left_PT_OC_popupmenu.
function left_PT_OC_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to left_PT_OC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns left_PT_OC_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from left_PT_OC_popupmenu


% --- Executes during object creation, after setting all properties.
function left_PT_OC_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to left_PT_OC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on selection change in right_PT_OC_popupmenu.
function right_PT_OC_popupmenu_Callback(hObject, eventdata, handles)
% hObject    handle to right_PT_OC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns right_PT_OC_popupmenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from right_PT_OC_popupmenu


% --- Executes during object creation, after setting all properties.
function right_PT_OC_popupmenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to right_PT_OC_popupmenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function left_RnumInc_OC_text_Callback(hObject, eventdata, handles)
% hObject    handle to left_RnumInc_OC_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of left_RnumInc_OC_text as text
%        str2double(get(hObject,'String')) returns contents of left_RnumInc_OC_text as a double


% --- Executes during object creation, after setting all properties.
function left_RnumInc_OC_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to left_RnumInc_OC_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function Right_RnumInc_OC_text_Callback(hObject, eventdata, handles)
% hObject    handle to Right_RnumInc_OC_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of Right_RnumInc_OC_text as text
%        str2double(get(hObject,'String')) returns contents of Right_RnumInc_OC_text as a double


% --- Executes during object creation, after setting all properties.
function Right_RnumInc_OC_text_CreateFcn(hObject, eventdata, handles)
% hObject    handle to Right_RnumInc_OC_text (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function leftREWmag_Callback(hObject, eventdata, handles)
% hObject    handle to leftREWmag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of leftREWmag as text
%        str2double(get(hObject,'String')) returns contents of leftREWmag as a double


% --- Executes during object creation, after setting all properties.
function leftREWmag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to leftREWmag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function rightREWmag_Callback(hObject, eventdata, handles)
% hObject    handle to rightREWmag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of rightREWmag as text
%        str2double(get(hObject,'String')) returns contents of rightREWmag as a double


% --- Executes during object creation, after setting all properties.
function rightREWmag_CreateFcn(hObject, eventdata, handles)
% hObject    handle to rightREWmag (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function trialPressLeft_Callback(hObject, eventdata, handles)
% hObject    handle to trialPressLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trialPressLeft as text
%        str2double(get(hObject,'String')) returns contents of trialPressLeft as a double


% --- Executes during object creation, after setting all properties.
function trialPressLeft_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialPressLeft (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function trailPressRight_Callback(hObject, eventdata, handles)
% hObject    handle to trailPressRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trailPressRight as text
%        str2double(get(hObject,'String')) returns contents of trailPressRight as a double


% --- Executes during object creation, after setting all properties.
function trailPressRight_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trailPressRight (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function TrialNum_Callback(hObject, eventdata, handles)
% hObject    handle to TrialNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of TrialNum as text
%        str2double(get(hObject,'String')) returns contents of TrialNum as a double


% --- Executes during object creation, after setting all properties.
function TrialNum_CreateFcn(hObject, eventdata, handles)
% hObject    handle to TrialNum (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function planB
if planB 
    return
end 


function CTrialTime_Callback(hObject, eventdata, handles)
% hObject    handle to CTrialTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of CTrialTime as text
%        str2double(get(hObject,'String')) returns contents of CTrialTime as a double


% --- Executes during object creation, after setting all properties.
function CTrialTime_CreateFcn(hObject, eventdata, handles)
% hObject    handle to CTrialTime (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function trialNumLim_Callback(hObject, eventdata, handles)
% hObject    handle to trialNumLim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trialNumLim as text
%        str2double(get(hObject,'String')) returns contents of trialNumLim as a double


% --- Executes during object creation, after setting all properties.
function trialNumLim_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialNumLim (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function trialTimeLimit_Callback(hObject, eventdata, handles)
% hObject    handle to trialTimeLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of trialTimeLimit as text
%        str2double(get(hObject,'String')) returns contents of trialTimeLimit as a double


% --- Executes during object creation, after setting all properties.
function trialTimeLimit_CreateFcn(hObject, eventdata, handles)
% hObject    handle to trialTimeLimit (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% --- Executes during object creation, after setting all properties.
function onOff_OC_checkbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to right_active_OC_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in onOff_OC_checkbox.
function onOff_OC_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to onOff_OC_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of onOff_OC_checkbox
if get(hObject, 'Value') == 1
    
    %set(handles.sessionLim, 'String', '0');
    set(handles.sessionLim, 'Enable', 'off');
    %set(handles.numCSminus, 'String', '0');
    set(handles.numCSminus, 'Enable', 'off');
    %set(handles.totPoissrew, 'String', '0');
    set(handles.totPoissrew, 'Enable', 'off');
    %set(handles.r_fxd, 'String', '0');
    set(handles.r_fxd, 'Enable', 'off'); 
    set(handles.csplusprob, 'String', '100');
    set(handles.csplusprob, 'Enable', 'off');
    set(handles.csminusprob, 'String', '0');
    set(handles.csminusprob, 'Enable', 'off');
    %set(handles.r_bgd, 'String', '0');
    set(handles.r_bgd, 'Enable', 'off');
    %set(handles.T_bgd, 'String', '0');
    set(handles.T_bgd, 'Enable', 'off'); 
    %set(handles.mindelaybgdtocue, 'String', '0');
    set(handles.mindelaybgdtocue, 'Enable', 'off');
    %set(handles.mindelayfxdtobgd, 'String', '0');
    set(handles.mindelayfxdtobgd, 'Enable', 'off');
    set(handles.checkboxnocues, 'Value', 0);
    set(handles.checkboxnocues, 'Enable', 'off');
    set(handles.checkboxexpiti, 'Value', 0);
    set(handles.checkboxtrialbytrial, 'Value', 0);
    set(handles.checkboxtrialbytrial, 'Enable', 'off');
    
    
    
    
else
    
    set(handles.sessionLim, 'String', '100');
    set(handles.sessionLim, 'Enable', 'on');
    set(handles.numCSminus, 'String', '50');
    set(handles.numCSminus, 'Enable', 'on');
    set(handles.totPoissrew, 'Enable', 'On');
    set(handles.totPoissrew, 'String', '100');
    set(handles.csplusprob, 'String', '100');
    set(handles.csplusprob, 'Enable', 'On');
    set(handles.csminusprob, 'String', '0');
    set(handles.csminusprob, 'Enable', 'On');
    set(handles.r_fxd, 'String', '50');
    set(handles.r_fxd, 'Enable', 'On');
    set(handles.r_bgd, 'String', '50');
    set(handles.r_bgd, 'Enable', 'On');
    set(handles.T_bgd, 'String', '6000');
    set(handles.T_bgd, 'Enable', 'on');
    set(handles.mindelaybgdtocue, 'String', '3000')
    set(handles.mindelaybgdtocue, 'Enable', 'on');
    set(handles.mindelayfxdtobgd, 'String', '3000');
    set(handles.mindelayfxdtobgd, 'Enable', 'on');
    set(handles.checkboxnocues, 'Value', '0');
    set(handles.checkboxnocues, 'Enable', 'on');
    set(handles.checkboxtrialbytrial, 'Enable', 'on');
    
    
    
   
end


% --- Executes on button press in left_active_OC_checkbox.
function left_active_OC_checkbox_Callback(hObject, eventdata, handles)
% hObject    handle to left_active_OC_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of left_active_OC_checkbox

if get(hObject, 'Value') == 0
    set(handles.leftREWmag, 'String', '0');
    set(handles.leftREWmag, 'Enable', 'off');
else
    set(handles.leftREWmag, 'String', '50');
    set(handles.leftREWmag, 'Enable', 'on');
end


% --- Executes during object creation, after setting all properties.
function right_active_OC_checkbox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to right_active_OC_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% --- Executes on button press in left_active_OC_checkbox.
function right_active_OC_checkbox_Callback(hObject, ~, handles)
% hObject    handle to left_active_OC_checkbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of left_active_OC_checkbox

if get(hObject, 'Value') == 0
    set(handles.rightREWmag, 'String', '0');
    set(handles.rightREWmag, 'Enable', 'off');
else
    set(handles.rightREWmag, 'String', '50');
    set(handles.rightREWmag, 'Enable', 'on');
end



function laserduration_Callback(hObject, eventdata, handles)
% hObject    handle to laserduration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of laserduration as text
%        str2double(get(hObject,'String')) returns contents of laserduration as a double


% --- Executes during object creation, after setting all properties.
function laserduration_CreateFcn(hObject, eventdata, handles)
% hObject    handle to laserduration (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



function laserlatency_Callback(hObject, eventdata, handles)
% hObject    handle to laserlatency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of laserlatency as text
%        str2double(get(hObject,'String')) returns contents of laserlatency as a double


% --- Executes during object creation, after setting all properties.
function laserlatency_CreateFcn(hObject, eventdata, handles)
% hObject    handle to laserlatency (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

function edit59_Callback(hObject, eventdata, handles)
% hObject    handle to edit59 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit59 as text
%        str2double(get(hObject,'String')) returns contents of edit59 as a double

% --- Executes during object creation, after setting all properties.
function edit59_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit59 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
