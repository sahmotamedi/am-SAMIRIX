function crop_and_segment_oct(volFilePath)
% This function crops a volume, segments it by using the JHU OCTSegmenter,
% and saves the result
% 
% This function accepts oct files in vol, img, and fda format and saved the
% segmentation output for img and fda together with image in octbin format 
% 
% The cropped and segmented vol file is saved in a seperate folder named
% segmented as the volume with the volume name plus "_segmented
% "_cropped_segmneted" added to its end
% 
% @param The path to the vol to be segmented 
% 
% @note Please keep track of the vol file directory, name, extension, which
% keep changing through the code. These variables always point to the file
% which is the target of our processing 
% 
% @author Seyedamirhosein Motamedi, Charité Universitätmedizin Berlin, October 2017
% 
% @usage crop_and_segment_oct('E:\data\EYE00123.vol');

%%
% Find the OCT marker folder path 
octMarkerPathSearch = what('octmarker64');
octMarkerPath = octMarkerPathSearch.path;

if contains(volFilePath, '.vol') % crop the volume if it is spectralis, topcon and cirus are always 6*6mm 
    % Parse the input vol file path
    [volFileDir, volFileName, volFileExt] = fileparts(volFilePath);
    
    % Crop the volume
    crop_vol(volFilePath, 6, volFileDir);
    
    % Change the vol file path to the cropped volume
    volFileName = [volFileName, '_cropped'];
    volFilePath = [volFileDir, '/', volFileName, volFileExt];
    
    % Save the vol file type 
    volFileType = 'vol';
    
    
elseif contains(volFilePath, '.fda') % No need to crop, it is always 6*6mm
    % Parse the input vol file path
    [volFileDir, volFileName, volFileExt] = fileparts(volFilePath);
    
    % Convert the fda file to img, and move it to a new folder named after
    % the fda file name (the converted img file does not have the name
    % inside). 
    volFileDir = [volFileDir, '/', volFileName];
    if ~isdir(volFileDir)
        mkdir(volFileDir);
    end
    
    % Convert the fda file to img 
    system(['"', octMarkerPath, '/convert_oct_data.exe"  --outputPath="', volFileDir, '/" -f img "', volFilePath, '"']);
    
    % Find the converted file and change the path to it 
    fileListSruct = dir(fullfile(volFileDir, '*.img'));
    fileListCell = struct2cell(fileListSruct);
    imgFilesList = fileListCell(1, :);
    if length(imgFilesList) > 1 % if so, out of somewhere there is more than one img file in the folder, and we dont know which one is the correct, so throw an error 
        error(['There must be only one img file in this folder: ', volFileDir]);
    end
    
    % Change the vol file path to the img file
    fdaFilePath = volFilePath; 
    volFileName = erase(imgFilesList{1}, '.img');
    volFileExt = '.img';
    volFilePath = [volFileDir, '/', volFileName, volFileExt];
    
    % Rename the vol file name if contains Unknown, by replacing unknown with macular
    if contains(volFilePath, 'Unknown') 
        volFileName = replace(volFileName, 'Unknown', 'Macular');
        movefile(volFilePath, [volFileDir, '/', volFileName, volFileExt]);
        volFilePath = [volFileDir, '/', volFileName, volFileExt];
    end
    
    % Save the vol file type 
    volFileType = 'fda';


elseif  contains(volFilePath, '.img') % if img, then no need for cropping or converting etc 
    % Save the original file path (for later usage)
    imgFilePath = volFilePath; 
    
    % If the img type of scan written as Unknown change it to Macular. if
    % it is an ONH volume, it was the reponsibility of the person who is
    % running the code to make sure that the volume belongs to a macula
    % data (Samirix designed to only segment macular volumes)
    nameChangedFlag = 0;
    if contains(volFilePath, 'Unknown') 
        movefile(volFilePath, replace(volFilePath, 'Unknown', 'Macular'));
        volFilePath = replace(volFilePath, 'Unknown', 'Macular');
        nameChangedFlag = 1;
    end
    
    % Parse the input vol file path
    [volFileDir, volFileName, volFileExt] = fileparts(volFilePath);
    
    % Save the vol file type 
    volFileType = 'img';
end

%% JHU segmentation 
% Define the params
params.resizedata = false;
params.minseg = false;
params.smooth = true;
params.segmethod = 2;
params.gridradii = [500 1500 2500];
params.logfile = false;
params.printtoscreen = true;
params.resultfolder = volFileDir;
params.overwrite_results = true;
params.saveXMLfiles = false;
params.displaygrid = false;
params.skip_completed = false;
params.displayresult = false;

% Define the vol files list
filenames = cellstr(volFilePath);

% Run the OCT segmentor
OCTLayerSegmentation(filenames, params)

%% Write the segmentation into the vol file
% Load the segmentation data
load([volFileDir, '/', volFileName, '/', volFileName , '_result']);

if strcmpi(volFileType, 'vol')
    % Open the vol
    [header, BScanHeader, slo, BScans, ThicknessGrid] = open_vol(volFilePath);
    
    % Replace the old segmentation data with the new one
    bd_pts = permute(bd_pts, [2 1 3]);
    BScanHeader.Boundary_1 = bd_pts(:, :, 1);   % ILM
    BScanHeader.Boundary_2 = bd_pts(:, :, 9);   % BM 
    BScanHeader.Boundary_3 = bd_pts(:, :, 2);   % RNFL
    BScanHeader.Boundary_5 = bd_pts(:, :, 3);   % IPL
    BScanHeader.Boundary_6 = bd_pts(:, :, 4);   % INL
    BScanHeader.Boundary_7 = bd_pts(:, :, 5);   % OPL
    BScanHeader.Boundary_9 = bd_pts(:, :, 6);   % ELM
    BScanHeader.Boundary_15 = bd_pts(:, :, 7);  % PR1
    BScanHeader.Boundary_16 = bd_pts(:, :, 8);  % PR2
    
    % Write INVALID in the rest of the bounderies
    INVALID = typecast(uint32(hex2dec('7f7fffff')),'single');
    BScanHeader.Boundary_4(1:header.NumBScans, 1:header.SizeX) = INVALID;
    BScanHeader.Boundary_8(1:header.NumBScans, 1:header.SizeX) = INVALID;
    BScanHeader.Boundary_10(1:header.NumBScans, 1:header.SizeX) = INVALID;
    BScanHeader.Boundary_11(1:header.NumBScans, 1:header.SizeX) = INVALID;
    BScanHeader.Boundary_12(1:header.NumBScans, 1:header.SizeX) = INVALID;
    BScanHeader.Boundary_13(1:header.NumBScans, 1:header.SizeX) = INVALID;
    BScanHeader.Boundary_14(1:header.NumBScans, 1:header.SizeX) = INVALID;
    BScanHeader.Boundary_17(1:header.NumBScans, 1:header.SizeX) = INVALID;
    
    % Update NumSeg
    BScanHeader.NumSeg(:) = 17;
    
    % Write the vol file again
    write_vol(header, BScanHeader, slo, BScans, ThicknessGrid, volFilePath);
    
    % Remove the JHU segmentation folder
    rmdir([volFileDir, '/', volFileName], 's');
    
    % Create a new folder to named segmented to save the cropped segmented vol files
    volFileDir = [volFileDir, '/segmented'];
    if ~isdir(volFileDir)
        mkdir(volFileDir);
    end
    
    % Rename the segmented volume and move it to the created segmented folder
    movefile(volFilePath, [volFileDir, '/', volFileName, '_segmented', volFileExt]);
    
    
elseif strcmpi(volFileType, 'fda')
    % Covert the fda file to oct bin (we save the segmentation of img and
    % fda alongside their volume data in octbin)
    system(['"', octMarkerPath, '/convert_oct_data.exe"  --outputPath="', volFileDir, '/" -f octbin "', fdaFilePath, '"']);
    
    % Find the octbin file just created and chenge its name to the fda file
    % name, change the path to it 
    fileListSruct = dir(fullfile(volFileDir, '*.octbin'));
    fileListCell = struct2cell(fileListSruct);
    octbinFilesList = fileListCell(1, :);
    if length(octbinFilesList) > 1 % if so, out of somewhere there is more than one octbin file in the folder, and we dont know which one is the correct, so throw an error 
        error(['There must be only one octbin file in this folder: ', volFileDir]);
    end
    volFileExt = '.octbin';
    [~, volFileName, ~] = fileparts(fdaFilePath);
    movefile([volFileDir, '/', octbinFilesList{1}], [volFileDir, '/', volFileName, volFileExt]);
    volFilePath = [volFileDir, '/', volFileName, volFileExt];
    
    % Open the octbin file 
    volOCTbin = readbin(volFilePath);
    
    % Delete the current segmentation in the octbin file and write new
    % segmentation on it 
    for iBscan = 1:length(volOCTbin.serie)
        volOCTbin.serie{1, iBscan}.segmentations = [];
        volOCTbin.serie{1, iBscan}.segmentations.ILM = bd_pts(:, iBscan, 1)';
        volOCTbin.serie{1, iBscan}.segmentations.RNFL = bd_pts(:, iBscan, 2)';
        volOCTbin.serie{1, iBscan}.segmentations.IPL = bd_pts(:, iBscan, 3)';
        volOCTbin.serie{1, iBscan}.segmentations.INL = bd_pts(:, iBscan, 4)';
        volOCTbin.serie{1, iBscan}.segmentations.OPL = bd_pts(:, iBscan, 5)';
        volOCTbin.serie{1, iBscan}.segmentations.ELM = bd_pts(:, iBscan, 6)';
        volOCTbin.serie{1, iBscan}.segmentations.PR1 = bd_pts(:, iBscan, 7)';
        volOCTbin.serie{1, iBscan}.segmentations.PR2 = bd_pts(:, iBscan, 8)';
        volOCTbin.serie{1, iBscan}.segmentations.BM = bd_pts(:, iBscan, 9)';
    end
    
    % Remove the folder containing img bin and segmentation
    rmdir(volFileDir, 's');
    
    % Save the volume in octbin format in a folder inside the original
    % volume folder, named segmented, with _segmented added to the name of
    % the octbin file
    [volFileDir, ~, ~] = fileparts(fdaFilePath);
    volFileDir = [volFileDir, '/segmented'];
    if ~isdir(volFileDir)
        mkdir(volFileDir);
    end
    volFilePath = [volFileDir, '/', volFileName, '_segmented_fda', volFileExt];
    writebin(volFilePath, volOCTbin);
    
    
elseif strcmpi(volFileType, 'img')
    % Chnage the type of img file back to its original if it was changed
    % from unknown to macular for the segmentation perpuses
    if nameChangedFlag == 1
        movefile(volFilePath, imgFilePath);
        volFilePath = imgFilePath;
    end
    % Parse the input vol file path
    [volFileDir, volFileName, ~] = fileparts(volFilePath);
    
    % Creat a temporary folder with a unique random name and convert the
    % img to octbin and save in the created folder (the octbin name is
    % unknown so it should be isolated from other possible octbin files)
    tempVolFileDir = tempname(volFileDir);
    if ~isdir(tempVolFileDir)
        mkdir(tempVolFileDir);
    end
    system(['"', octMarkerPath, '/convert_oct_data.exe"  --outputPath="', tempVolFileDir, '/" -f octbin "', volFilePath, '"']);
    
    % Read the octbin file
    fileListSruct = dir(fullfile(tempVolFileDir, '*.octbin'));
    fileListCell = struct2cell(fileListSruct);
    octbinFilesList = fileListCell(1, :);
    if length(octbinFilesList) > 1 % if so, out of somewhere there is more than one octbin file in the folder, and we dont know which one is the correct, so throw an error 
        error(['There must be only one octbin file in this folder: ', tempVolFileDir]);
    end
    volOCTbin = readbin([tempVolFileDir, '/', octbinFilesList{1}]);
    
    % Delete the current segmentation in the octbin file and write new
    % segmentation on it 
    for iBscan = 1:length(volOCTbin.serie)
        volOCTbin.serie{1, iBscan}.segmentations = [];
        volOCTbin.serie{1, iBscan}.segmentations.ILM = bd_pts(:, iBscan, 1)';
        volOCTbin.serie{1, iBscan}.segmentations.RNFL = bd_pts(:, iBscan, 2)';
        volOCTbin.serie{1, iBscan}.segmentations.IPL = bd_pts(:, iBscan, 3)';
        volOCTbin.serie{1, iBscan}.segmentations.INL = bd_pts(:, iBscan, 4)';
        volOCTbin.serie{1, iBscan}.segmentations.OPL = bd_pts(:, iBscan, 5)';
        volOCTbin.serie{1, iBscan}.segmentations.ELM = bd_pts(:, iBscan, 6)';
        volOCTbin.serie{1, iBscan}.segmentations.PR1 = bd_pts(:, iBscan, 7)';
        volOCTbin.serie{1, iBscan}.segmentations.PR2 = bd_pts(:, iBscan, 8)';
        volOCTbin.serie{1, iBscan}.segmentations.BM = bd_pts(:, iBscan, 9)';
    end
    
    % Remove the folder containing octbin
    rmdir(tempVolFileDir, 's');
    
    % Remove the folder containg the JHU segmentation output
    rmdir([volFileDir, '/', volFileName], 's');
    
    % Save the volume in octbin format in a folder inside the original
    % volume folder, named segmented, with _segmented added to the name of
    % the octbin file
    volFileDir = [volFileDir, '/segmented'];
    volFileExt = '.octbin';
    if ~isdir(volFileDir)
        mkdir(volFileDir);
    end
    volFilePath = [volFileDir, '/', volFileName, '_segmented_img', volFileExt];
    writebin(volFilePath, volOCTbin);
end 

