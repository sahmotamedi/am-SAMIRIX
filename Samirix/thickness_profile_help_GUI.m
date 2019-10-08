function varargout = thickness_profile_help_GUI(varargin)
% thickness_profile_help_GUI MATLAB code for thickness_profile_help_GUI.fig
%      thickness_profile_help_GUI, by itself, creates a new thickness_profile_help_GUI or raises the existing
%      singleton*.
%
%      H = thickness_profile_help_GUI returns the handle to a new thickness_profile_help_GUI or the handle to
%      the existing singleton*.
%
%      thickness_profile_help_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in thickness_profile_help_GUI.M with the given input arguments.
%
%      thickness_profile_help_GUI('Property','Value',...) creates a new thickness_profile_help_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before thickness_profile_help_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to thickness_profile_help_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help thickness_profile_help_GUI

% Last Modified by GUIDE v2.5 17-Nov-2017 17:38:39

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @thickness_profile_help_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @thickness_profile_help_GUI_OutputFcn, ...
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


% --- Executes just before thickness_profile_help_GUI is made visible.
function thickness_profile_help_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to thickness_profile_help_GUI (see VARARGIN)

% Choose default command line output for thickness_profile_help_GUI
handles.output = hObject;

% Show the help fig
axes(handles.axes1);
imshow('thicknessMapHelp - Kopie.png')

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes thickness_profile_help_GUI wait for user response (see UIRESUME)
% uiwait(handles.thickness_profile_help_GUI);


% --- Outputs from this function are returned to the command line.
function varargout = thickness_profile_help_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
