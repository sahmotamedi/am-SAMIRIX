function varargout = Samirix_GUI(varargin)
% SAMIRIX_GUI MATLAB code for Samirix_GUI.fig
%      SAMIRIX_GUI, by itself, creates a new SAMIRIX_GUI or raises the existing
%      singleton*.
%
%      H = SAMIRIX_GUI returns the handle to a new SAMIRIX_GUI or the handle to
%      the existing singleton*.
%
%      SAMIRIX_GUI('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in SAMIRIX_GUI.M with the given input arguments.
%
%      SAMIRIX_GUI('Property','Value',...) creates a new SAMIRIX_GUI or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before Samirix_GUI_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to Samirix_GUI_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help Samirix_GUI

% Last Modified by GUIDE v2.5 20-Nov-2018 16:53:46

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @Samirix_GUI_OpeningFcn, ...
                   'gui_OutputFcn',  @Samirix_GUI_OutputFcn, ...
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


% --------------- Opening function 
% --- Executes just before Samirix_GUI is made visible.
function Samirix_GUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to Samirix_GUI (see VARARGIN)

% Choose default command line output for Samirix_GUI
handles.output = hObject;

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes Samirix_GUI wait for user response (see UIRESUME)
% uiwait(handles.Samirix_GUI);


% --- Outputs from this function are returned to the command line.
function varargout = Samirix_GUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;

% -------------- Segment all button
% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Segment all the vol img and fda files in the folder
volFilesList = handles.listbox1.String;
% Filter the vol file list to not contain octbin volumes which cannot be
% segmented 
if ~isempty(volFilesList)
    volFilesList(cellfun(@(x) contains(x, '.octbin'), volFilesList)) = [];
end
if isempty(volFilesList)
    % Retrun an error that the OCT files list is empty
    msgbox({'OCT Files list is empty!'; 'Select a folder contaitning OCT files first!'}, 'Error','error', 'modal');
    % Retrun from this function
    return
end

% Creat a wait bar
handleWaitBar = waitbar(0, 'Segmenting! Please be patient...', 'WindowStyle', 'modal');

% Declare a cell for saving error messages
errorCell = cell(0,0);
errorCounter = 0;

% Segment the vol file(s) one by one
for iVolume = 1:length(volFilesList)
    volFilePath = cell2mat(strcat([handles.edit3.String, '/', volFilesList(iVolume)]));
    try
        % Call the crop_and_segment_oct function
        crop_and_segment_oct(volFilePath);
    catch ME
        errorCounter = errorCounter + 1;
        errorCell{errorCounter, 1} = [volFilePath, '   ', ME.message];
        continue
    end
    % Update the wait bar
    waitbar(iVolume/length(volFilesList));
end

% Close the wait bar
close(handleWaitBar);

% Save the error cell if any happened
if (errorCounter > 0)
    errorFileID = fopen([handles.edit3.String, '/error.txt'], 'at');
    fprintf(errorFileID, '%s\n', errorCell{:});
    fclose(errorFileID);
end


% Update the listbox with the names of the files in the selected folder ends with .vol
fileListSruct = [dir(fullfile(handles.edit3.String, '*.vol')); dir(fullfile(handles.edit3.String, '*.img')); dir(fullfile(handles.edit3.String, '*.fda')); dir(fullfile(handles.edit3.String, '*.octbin'))];
fileListCell = struct2cell(fileListSruct);
volFilesList = fileListCell(1, :);
handles.listbox1.String = volFilesList;

% Update the list box value to 1
handles.listbox1.Value = 1;

% Update handles structure
guidata(hObject, handles)


%------------- Segment selected button
% --- Executes on button press in pushbutton7.
function pushbutton7_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton7 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Segment selected vol img and fda files in the folder
volFilesList = handles.listbox1.String;
% Filter the vol file list to not contain octbin volumes which cannot be
% segmented 
if ~isempty(volFilesList)
    volFilesList(cellfun(@(x) contains(x, '.octbin'), volFilesList)) = [];
end
if isempty(volFilesList)
    % Retrun an error that the OCT files list is empty
    msgbox({'OCT Files list is empty!'; 'Select a folder contaitning OCT files first!'}, 'Error','error', 'modal');
    % Return from this function 
    return
end

% Select the vol files selected by the user
volFilesList = volFilesList(handles.listbox1.Value);

% Creat a wait bar
handleWaitBar = waitbar(0, 'Segmenting! Please be patient...', 'WindowStyle', 'modal');

% Declare a cell for saving error messages
errorCell = cell(0,0);
errorCounter = 0;

% Segment the vol file(s) one by one
for iVolume = 1:length(volFilesList)
    volFilePath = cell2mat(strcat([handles.edit3.String, '/', volFilesList(iVolume)]));
    try
        % Call the crop_and_segment_oct function
        crop_and_segment_oct(volFilePath);
    catch ME
        errorCounter = errorCounter + 1;
        errorCell{errorCounter, 1} = [volFilePath, '   ', ME.message];
        continue
    end
    % Update the wait bar
    waitbar(iVolume/length(volFilesList));
end

% Close the wait bar
close(handleWaitBar);

% Save the error cell if any happened
if (errorCounter > 0)
    errorFileID = fopen([handles.edit3.String, '/error.txt'], 'at');
    fprintf(errorFileID, '%s\n', errorCell{:});
    fclose(errorFileID);
end


% Update the listbox with the names of the files in the selected folder ends with .vol
fileListSruct = [dir(fullfile(handles.edit3.String, '*.vol')); dir(fullfile(handles.edit3.String, '*.img')); dir(fullfile(handles.edit3.String, '*.fda')); dir(fullfile(handles.edit3.String, '*.octbin'))];
fileListCell = struct2cell(fileListSruct);
volFilesList = fileListCell(1, :);
handles.listbox1.String = volFilesList;

% Update the list box value to 1
handles.listbox1.Value = 1;

% Update handles structure
guidata(hObject, handles)

% --------------- Show and correct button
% --- Executes on button press in pushbutton3.
function pushbutton3_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get the list of vol files
volFilesList = handles.listbox1.String;
if isempty(volFilesList)
    % Retrun an error that the OCT files list is empty
    msgbox({'OCT Files list is empty!'; 'Select a folder contaitning OCT files first!'}, 'Error','error', 'modal');
    % Return from this function 
    return 
end

% Get the vol file selected
listboxList = handles.listbox1.String;
handles.listbox1.Value = handles.listbox1.Value(1);         % If multiple volumes is selected, the first one is assemed to be the volume to be showed
volFilePath = cell2mat(strcat([handles.edit3.String, '/', listboxList(handles.listbox1.Value)]));

%%%%%%%%% OCT-Marker
try
    % Call the correct_segmentation_manual function
    correct_segmentation_manual(volFilePath);
catch ME
    errorMessage = ME.message;
    if strcmpi(ME.message, 'not a bin file')
        errorMessage = 'Delete the folder with the same name as the selected file in the selected directory!';
    end
    errorDialogHandle = errordlg(errorMessage, 'Error', 'modal');
    uiwait(errorDialogHandle)
end

% %%%%%%% segEdit
% % Form the path of output file
% % Add '_corrected' to the end of the file name (if not included before)
% if isempty(strfind(volFilePath, 'corrected'))
%     [volFileDir, volFileName, volFileExt] = fileparts(volFilePath);
%     outputVolFilePath = [volFileDir, '/', volFileName, '_corrected', volFileExt];
% else
%     outputVolFilePath = volFilePath;
% end
% % Form the structure consists of input and output vol files path to pass to
% % the GUI function
% dataPath.inputVolFilePath = volFilePath;
% dataPath.outputVolFilePath = outputVolFilePath;
% % Call the segEdit
% segEdit_GUI(dataPath);
% uiwait

% Update the listbox with the names of the files in the selected folder ends with .vol
fileListSruct = [dir(fullfile(handles.edit3.String, '*.vol')); dir(fullfile(handles.edit3.String, '*.img')); dir(fullfile(handles.edit3.String, '*.fda')); dir(fullfile(handles.edit3.String, '*.octbin'))];
fileListCell = struct2cell(fileListSruct);
volFilesList = fileListCell(1, :);
handles.listbox1.String = volFilesList;

% Update handles structure
guidata(hObject, handles)



% --------------- Browse Button
% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% receive the data path and show it in the text box
if isempty(handles.edit3.String)
    dataPath = uigetdir();
else
    dataPath = uigetdir(handles.edit3.String);
end
if dataPath ~= 0 % If a path has been returned, otherwise jump out of this function 
    handles.edit3.String = dataPath;
else
    return
end

% Update the listbox with the names of the files in the selected folder
% ends with .vol .img and .fda
fileListSruct = [dir(fullfile(dataPath, '*.vol')); dir(fullfile(dataPath, '*.img')); dir(fullfile(dataPath, '*.fda')); dir(fullfile(dataPath, '*.octbin'))];
fileListCell = struct2cell(fileListSruct);
volFilesList = fileListCell(1, :);
handles.listbox1.String = volFilesList;

% Update the list box value to 1
handles.listbox1.Value = 1;

% Update handles structure
guidata(hObject, handles)


% ----------- List box double click event
% --- Executes on selection change in listbox1.
function listbox1_Callback(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% If double clicked on an item in the list, open the file 
if strcmp(get(handles.Samirix_GUI,'SelectionType'),'open')
    % Get the list of vol files
    volFilesList = handles.listbox1.String;
    if isempty(volFilesList)
        % Retrun an error that the OCT files list is empty
        msgbox({'OCT Files list is empty!'; 'Select a folder contaitning OCT files first!'}, 'Error','error', 'modal');
        % Return from this function
        return
    end
    
    % Get the vol file selected
    listboxList = handles.listbox1.String;
    volFilePath = cell2mat(strcat([handles.edit3.String, '/', listboxList(handles.listbox1.Value)]));
    
    %%%%%%%%% OCT-Marker
    try
        % Call the correct_segmentation_manual function
        correct_segmentation_manual(volFilePath);
    catch ME
        errorMessage = ME.message;
        if strcmpi(ME.message, 'not a bin file')
            errorMessage = 'Delete the folder with the same name as the selected file in the selected directory!';
        end
        errorDialogHandle = errordlg(errorMessage, 'Error', 'modal');
        uiwait(errorDialogHandle)
    end
    
%     %%%%%%% segEdit
%     % Form the path of output file
%     % Add '_corrected' to the end of the file name (if not included before)
%     if isempty(strfind(volFilePath, 'corrected'))
%         [volFileDir, volFileName, volFileExt] = fileparts(volFilePath);
%         outputVolFilePath = [volFileDir, '/', volFileName, '_corrected', volFileExt];
%     else
%         outputVolFilePath = volFilePath;
%     end
%     % Form the structure consists of input and output vol files path to pass to
%     % the GUI function
%     dataPath.inputVolFilePath = volFilePath;
%     dataPath.outputVolFilePath = outputVolFilePath;
%     % Call the segEdit
%     segEdit_GUI(dataPath);
%     uiwait
    
    % Update the listbox with the names of the files in the selected folder ends with .vol
    fileListSruct = [dir(fullfile(handles.edit3.String, '*.vol')); dir(fullfile(handles.edit3.String, '*.img')); dir(fullfile(handles.edit3.String, '*.fda')); dir(fullfile(handles.edit3.String, '*.octbin'))];
    fileListCell = struct2cell(fileListSruct);
    volFilesList = fileListCell(1, :);
    handles.listbox1.String = volFilesList;
    
    % Update handles structure
    guidata(hObject, handles)
end


% --- Executes during object creation, after setting all properties.
function listbox1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end

% ----------- Thickness Report Button 
% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get the list of vol files
volFilesList = handles.listbox1.String;
if isempty(volFilesList)
    % Retrun an error that the OCT files list is empty
    msgbox({'OCT Files list is empty!'; 'Select a folder contaitning OCT files first!'}, 'Error','error', 'modal');
    % Return from this function 
    return 
end

% Open the thickness profile export GUI
thickness_profile_GUI

% ---------------- Closing function 
% --- Executes when user attempts to close Samirix_GUI.
function Samirix_GUI_CloseRequestFcn(hObject, eventdata, handles)
% hObject    handle to Samirix_GUI (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Close the thickness_profile_help_GUI if open 
if ~isempty(findobj('tag', 'thickness_profile_help_GUI'))
    close(thickness_profile_help_GUI);
end

% Close the thickness_profile_GUI if open 
if ~isempty(findobj('tag', 'thickness_profile_GUI'))
    close(thickness_profile_GUI);
end

% Hint: delete(hObject) closes the figure
delete(hObject);



function edit3_Callback(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edit3 as text
%        str2double(get(hObject,'String')) returns contents of edit3 as a double
% receive the data path and show it in the text box

% Assign the text from the edit box to the data path, if it is not a valid
% folder path, the list box gets empty and no error is passed
dataPath = handles.edit3.String;

% Update the listbox with the names of the files in the selected folder
% ends with .vol .img and .fda
fileListSruct = [dir(fullfile(dataPath, '*.vol')); dir(fullfile(dataPath, '*.img')); dir(fullfile(dataPath, '*.fda')); dir(fullfile(dataPath, '*.octbin'))];
fileListCell = struct2cell(fileListSruct);
volFilesList = fileListCell(1, :);
handles.listbox1.String = volFilesList;

% Update the list box value to 1
handles.listbox1.Value = 1;

% Update handles structure
guidata(hObject, handles)


% --- Executes during object creation, after setting all properties.
function edit3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edit3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
