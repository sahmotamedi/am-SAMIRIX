function crop_and_segment_oct(volFilePath)
% This function crops a volume, segments it by using the JHU OCTSegmenter,
% and saves the result
% 
% The cropped and segmented vol file is saved in the same folder as the
% volume with the volume name plus "_cropped_segmneted" added to its end
% 
% @param The path to the vol to be segmented 
% 
% @author Seyedamirhosein Motamedi, Charité Universitätmedizin Berlin, October 2017
% 
% @usage crop_and_segment_oct('E:\data\EYE00123.vol');

%%
% Parse the input vol file path
[volFileDir, volFileName, volFileExt] = fileparts(volFilePath);

% Crop the volume
crop_vol(volFilePath, 6, volFileDir);

% Change the vol file path to the cropped volume 
volFileName = [volFileName, '_cropped'];
volFilePath = [volFileDir, '\', volFileName, volFileExt];

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
load([volFileDir, '\', volFileName, '\', volFileName , '_result']);

% Open the vol 
[header, BScanHeader, slo, BScans, ThicknessGrid] = open_vol(volFilePath);

% Replace the old segmentation data with the new one
bd_pts = permute(bd_pts, [2 1 3]);
BScanHeader.Boundary_1 = bd_pts(:, :, 1);
BScanHeader.Boundary_2 = bd_pts(:, :, 9);
BScanHeader.Boundary_3 = bd_pts(:, :, 2);
BScanHeader.Boundary_5 = bd_pts(:, :, 3);
BScanHeader.Boundary_6 = bd_pts(:, :, 4);
BScanHeader.Boundary_7 = bd_pts(:, :, 5);
BScanHeader.Boundary_9 = bd_pts(:, :, 6);
BScanHeader.Boundary_15 = bd_pts(:, :, 7);
BScanHeader.Boundary_16 = bd_pts(:, :, 8);

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
rmdir([volFileDir, '\', volFileName], 's');

% Create a new folder to named segmented to save the cropped segmented vol files
volFileDir = [volFileDir, '\segmented'];
if ~isdir(volFileDir)
    mkdir(volFileDir);
end

% Rename the segmented volume and move it to the created segmented folder
movefile(volFilePath, [volFileDir, '\', volFileName, '_segmented', volFileExt]);