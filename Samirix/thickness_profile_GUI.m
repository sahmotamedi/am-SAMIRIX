function varargout = thickness_profile_GUI(varargin)
% thickness_profile_GUI MATLAB code for thickness_profile_GUI.fig
%      thickness_profile_GUI, by itself, creates a new thickness_profile_GUI or raises the existing
%      singleton*.
%
%      H = thickness_profile_GUI returns the handle to a new thickness_profile_GUI or the handle to
%      the existing singleton*.
%
%      thickness_profile_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in thickness_profile_GUI.M with the given input arguments.
%
%      thickness_profile_GUI('Property','Value',...) creates a new thickness_profile_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before thickness_profile_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to thickness_profile_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help thickness_profile_GUI

% Last Modified by GUIDE v2.5 17-Nov-2017 17:33:43

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @thickness_profile_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @thickness_profile_GUI_OutputFcn, ...
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


% --- Executes just before thickness_profile_GUI is made visible.
function thickness_profile_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to thickness_profile_GUI (see VARARGIN)

% Choose default command line output for thickness_profile_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes thickness_profile_GUI wait for user response (see UIRESUME)
% uiwait(handles.thickness_profile_GUI);


% --- Outputs from this function are returned to the command line.
function varargout = thickness_profile_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% ------------- Thickness Export Button
% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Find Samirix Gui
hSamirixGui = findobj('tag', 'Samirix_GUI');
if ~isempty(hSamirixGui) % If exists
    
    samirixGuiData = guidata(hSamirixGui);
    % Get the vol files dir and names from the Samirix GUI
    volFilesList = samirixGuiData.listbox1.String;
    volFilePath = samirixGuiData.edit3.String;
    volFilesFullPath = strcat(volFilePath, '/', volFilesList);
    
    % Get the upper and lower boudaries
    upperBoundary = handles.uibuttongroup1.SelectedObject.String;
    lowerBoundary = handles.uibuttongroup2.SelectedObject.String;
    
    % Determine the thickness profile grid type 
    if strcmpi(handles.popupmenu1.String{handles.popupmenu1.Value}, '1-to-5 mm Doughnut with Centering')
        thicknessProfileGridType = 5;
%     Cirrus Annulus has been commented out because the calculations need to be revised and tested. If this is to be added again, add "Cirrus Annulus" to the String properties of the GUI    
%     elseif strcmpi(handles.popupmenu1.String{handles.popupmenu1.Value}, 'cirrus annulus')
%         thicknessProfileGridType = 4.8;
    elseif strcmpi(handles.popupmenu1.String{handles.popupmenu1.Value}, '1, 2.22, 3.45 mm')
        thicknessProfileGridType = 3.45;
    elseif strcmpi(handles.popupmenu1.String{handles.popupmenu1.Value}, '1, 2, 3 mm')
        thicknessProfileGridType = 3;
    else % EDTRS
        thicknessProfileGridType = 6;
    end
    
    % Form the predefined report saving path based on what selected
    preDefinesSavingPath = [volFilePath, '/thickness_report_', upperBoundary, '_', lowerBoundary, '_', strrep(num2str(thicknessProfileGridType), '.', '_'), '_mm', '.csv'];
    
    % Ask the user where to save the thickness profile
    [fileName, pathName] = uiputfile('*.csv', 'Save as', preDefinesSavingPath);
    thicknessReportSavingPath = [pathName, fileName];
    
    % Generate the thickness report
    if thicknessProfileGridType == 5
        generate_thickness_report_batch_1_to_5_octbi_vol(volFilesFullPath, upperBoundary, lowerBoundary, thicknessReportSavingPath);
    else
        generate_thickness_report_batch(volFilesFullPath, upperBoundary, lowerBoundary, thicknessProfileGridType, thicknessReportSavingPath);
    end
end

% ------------- Help Button
% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Call the thickness map help GUI
thickness_profile_help_GUI


% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1


% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% ------------- GUI closing function 
% --- Executes when user attempts to close thickness_profile_GUI.
function thickness_profile_GUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to thickness_profile_GUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Close the thickness_map_help_GUI if open 
if ~isempty(findobj('tag', 'thickness_profile_help_GUI'))
    close(thickness_profile_help_GUI);
end

% Hint: delete(hObject) closes the figure
delete(hObject);
