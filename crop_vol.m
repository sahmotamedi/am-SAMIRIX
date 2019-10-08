function crop_vol(varargin)
% @brief This function crops OCT volumes 
% 
% This function opens a volume, crops it and correct all the information
% related to the volume (header, bScanHeader and etc), and then saves the
% cropped volume in .vol format 
% 
% @param varargin If nothing passed, the cropped volume(s) is saved in a
% new folder called cropped in the volume(s) directory, the volume(s) is
% cropped to 6*6mm, and the volume directory is raken from a user
% interface, the first argument passed is the path to a vol file or a
% folder contains vol files, the second argument passed assumed as the size
% of the cropped volume so the output volume would be N*Nmm, and the third
% argument passed assumed as the path to the folder where the cropped
% volume(s) is saved
% 
% @note If no input is given, the user interface only gets a folder path,
% so all the volumes in that folder is cropped. If cropping a single volume
% is intended please pass the vol file path as the first argument
% 
% @author Seyedamirhosein Motamedi, Charité Universitätmedizin Berlin, April 2017
% 
% @usage crop_vol('Z:\CIS_GCIPL_predict\SpectralisDB_CIS_2016-02-24_vol');

%%
% Determine the suqare width and the data path based on the number of input
% argument
if (isempty(varargin))
    squareWidthmm = 6;
    % Get the forlder path from the user
    dataPath = uigetdir();
elseif nargin == 1
    dataPath = varargin{1};
    squareWidthmm = 6;
elseif nargin >= 2
    dataPath = varargin{1};
    squareWidthmm = varargin{2};
end

% Check if the provided path is the path to a folder or to a single volume file 
if (isdir(dataPath))    % If the provided path is to a folder, find all the 3D volumes stored as seperate BScans in the folder
    % Find .vol files in the folder
    filesList = cellstr(ls(dataPath));
    volumeFilesList = filesList(~cellfun('isempty', strfind(filesList, '.vol')));
    volumeFilesPath = cellfun(@(x) [dataPath, '/', x], volumeFilesList, 'UniformOutput', false);
else                    % If the provided path is to a single volume, only that volume will be processed 
    volumeFilesPath{1} = dataPath;
end

for iVolume = 1:size(volumeFilesPath, 1)
try
    % Read the volume
    volPath = volumeFilesPath{iVolume};
    [header, bScanHeader, sloImage, bScans, thicknessGrid] = open_vol(volPath);
    
    %% Correct the fovea (center) point
    % Find the B-Scan and the A-Scan which the fovea is located on from the fovea coordinate on the SLO image
    sloFoveaXmm = thicknessGrid.CenterPos(1);    % The position of the fovea in the horizontal direction in milimeters from the top left corner of the SLO image
    sloFoveaYmm = thicknessGrid.CenterPos(2);    % The position of the fovea in the vertical direction in milimeters from the top left corner of the SLO image
    sloVolumeAngle = atan((bScanHeader.EndY(1)-bScanHeader.EndY(end))/(bScanHeader.EndX(1)-bScanHeader.EndX(end))); % The angle between the SLO image and the volume grid on the SLO image plane
    % Correct the angle if the actual angle is not between [-pi/2, pi/2] (atan output is always between -pi/2 and pi/2)
    if bScanHeader.EndX(end) > bScanHeader.EndX(1)
        sloVolumeAngle = sloVolumeAngle + pi;
    end
    volumeFoveaYmm = (sloFoveaXmm-bScanHeader.EndX(end))*cos(sloVolumeAngle) + (sloFoveaYmm-bScanHeader.EndY(end))*sin(sloVolumeAngle);     % The position of the fovea in the y direction in mm in the volume Grid (Note: the y direction in the volume is different from the y direction in the slo image)
    volumeFoveaXmm = -(sloFoveaXmm-bScanHeader.EndX(end))*sin(sloVolumeAngle) + (sloFoveaYmm-bScanHeader.EndY(end))*cos(sloVolumeAngle);    % The position of the fovea in the x direction in mm in the volume Grid (Note: the x direction in the volume is different from the x direction in the slo image)
    foveaBScanMan = header.NumBScans - (round(volumeFoveaYmm/header.Distance));    % The number of the B-Scan which the fovea in located on it
    foveaAScanMan = header.SizeX - (round(volumeFoveaXmm/header.ScaleX));          % The number of the A-Scan which the fovea in located on it
    
    % Create relative surface
    ILMrelFull = bScanHeader.Boundary_2-bScanHeader.Boundary_1;
    ILMrelFull = round(ILMrelFull,2);
    
    % Get the region of 2mm around (1mm from left, right, top and bottom)
    % the manual center
    distBScans2mm = round(1/header.Distance);
    distAScans2mm = round(1/header.ScaleX);
    marginLeftBScans2mm  = foveaAScanMan - distAScans2mm;
    marginRightBScans2mm = foveaAScanMan + distAScans2mm;
    startBScans2mm       = foveaBScanMan - distBScans2mm;
    endBScans2mm         = foveaBScanMan + distBScans2mm;
    
    % Search for the minimum point in the 2mm area near the manually determined
    % fovea (and call it automatically determined fovea point)
    minSearchRegion2mm = ILMrelFull(startBScans2mm:endBScans2mm,marginLeftBScans2mm:marginRightBScans2mm);
    [minVal2mm, ~] = min(minSearchRegion2mm(:));
    lowestIndVec = find(minSearchRegion2mm == minVal2mm);
    nrofCenters = numel(lowestIndVec);
    if(mod(nrofCenters,2)==0)
        index2mm = lowestIndVec(nrofCenters/2);
    else
        index2mm = median(lowestIndVec);
    end
    [pos1,pos2] = ind2sub(size(minSearchRegion2mm),index2mm);
    foveaBScanAuto = pos1 + startBScans2mm - 1;
    foveaAScanAuto = pos2 + marginLeftBScans2mm - 1;
    
    % Convert the automatically found fovea point into the distance in mm
    % from the left top corner of the slo
    volumeFoveaAutoYmm = (header.NumBScans - foveaBScanAuto) * header.Distance;
    volumeFoveaAutoXmm = (header.SizeX - foveaAScanAuto) * header.ScaleX;
    sloFoveaAutoXmm = volumeFoveaAutoYmm*cos(sloVolumeAngle)-volumeFoveaAutoXmm*sin(sloVolumeAngle)+bScanHeader.EndX(end);
    sloFoveaAutoYmm = volumeFoveaAutoYmm*sin(sloVolumeAngle)+volumeFoveaAutoXmm*cos(sloVolumeAngle)+bScanHeader.EndY(end);
    
    % Update the center position in the thickness grid
    thicknessGrid.CenterPos = [sloFoveaAutoXmm, sloFoveaAutoYmm];
    
    %% Crop
    % @note The sequence of cropping (segmentation data, BScans, ...) in
    % this section is important 
    
    % Calcualte the number of BScans and AScans around the center point for
    % cropping
    nCroppedVolBScans = 2*floor(squareWidthmm/header.Distance/2)+1;
    nCroppedVolAScans = 2*floor(squareWidthmm/header.ScaleX/2)+1;
    
    % Define the first and last BScans and AScans for cropping
    croppingFirstBScan = foveaBScanAuto-(nCroppedVolBScans-1)/2;
    croppingLastBScan = foveaBScanAuto+(nCroppedVolBScans-1)/2;
    croppingFirstAScan = foveaAScanAuto-(nCroppedVolAScans-1)/2;
    croppingLastAScan = foveaAScanAuto+(nCroppedVolAScans-1)/2;
    
    % If the volume is smaller than the cropping size, throw a warning
    % message and change variables in order to crop the volume from the
    % volume sides which the volume exceeds the cropping borders
    if (croppingFirstBScan < 1)
        if (croppingLastBScan > header.NumBScans)
            warning('The volume %s in the y direction (BScans) was not cropped. The volume in this direction is smaller than the cropping size!', volPath)
            croppingFirstBScan = 1;
            croppingLastBScan = header.NumBScans;
            nCroppedVolBScans = header.NumBScans;
        else 
            warning('The volume %s in the y direction (BScans) was not cropped. The volume in this direction from one side is smaller than the cropping size!', volPath)
            croppingFirstBScan = 1;
            nCroppedVolBScans = croppingLastBScan;
        end
    elseif (croppingLastBScan > header.NumBScans)
        warning('The volume %s in the y direction (BScans) was not cropped. The volume in this direction from one side is smaller than the cropping size!', volPath)
        croppingLastBScan = header.NumBScans;
        nCroppedVolBScans = header.NumBScans-croppingFirstBScan+1;
    end
    if (croppingFirstAScan < 1)
        if (croppingLastAScan > header.SizeX)
            warning('The volume %s in the x direction (AScans) was not cropped. The volume in this direction is smaller than the cropping size!', volPath)
            croppingFirstAScan = 1;
            croppingLastAScan = header.SizeX;
            nCroppedVolAScans = header.SizeX;
        else 
            warning('The volume %s in the x direction (AScans) was not cropped. The volume in this direction from one side is smaller than the cropping size!', volPath)
            croppingFirstAScan = 1;
            nCroppedVolAScans = croppingLastAScan;
        end
    elseif (croppingLastAScan > header.SizeX)
        warning('The volume %s in the x direction (AScans) was not cropped. The volume in this direction from one side is smaller than the cropping size!', volPath)
        croppingLastAScan = header.SizeX;
        nCroppedVolAScans = header.SizeX-croppingFirstAScan+1;
    end
    
    
    % Crop the segmentation data
    for iBoundary = 1:bScanHeader.NumSeg(1)
        bScanHeader.(sprintf('Boundary_%d', iBoundary)) = bScanHeader.(sprintf('Boundary_%d', iBoundary))(croppingFirstBScan:croppingLastBScan, croppingFirstAScan:croppingLastAScan);
    end
    
    % Crop BScans
    bScans = bScans(:, croppingFirstAScan:croppingLastAScan, croppingFirstBScan:croppingLastBScan);
        
    % Recalculate the start and end of each BScans (StartX, StartY, EndX,
    % EndY) and update them (PLEASE NOTE that I lost half of my brain's
    % grey matter to calculate the below formulas, so DO NNOT change them)
    bScanHeader.StartX = bScanHeader.StartX + (croppingFirstAScan-1)*header.ScaleX*cos(3*pi/2+sloVolumeAngle);
    bScanHeader.StartY = bScanHeader.StartY + (croppingFirstAScan-1)*header.ScaleX*sin(3*pi/2+sloVolumeAngle);
    bScanHeader.EndX = bScanHeader.EndX + (header.SizeX-(croppingLastAScan))*header.ScaleX*cos(pi/2+sloVolumeAngle);
    bScanHeader.EndY = bScanHeader.EndY + (header.SizeX-(croppingLastAScan))*header.ScaleX*sin(pi/2+sloVolumeAngle);
    
    % Update the SizeX and NumBScans in the header
    header.NumBScans = nCroppedVolBScans;
    header.SizeX = nCroppedVolAScans;
    
    % Update the GridOffset
    header.GridOffset = 2048+header.SizeXSlo*header.SizeYSlo+nCroppedVolBScans*(header.BScanHdrSize+header.SizeX*header.SizeZ*4);
    
    % Crop bScanHeader
    bScanHeader.StartX = bScanHeader.StartX(croppingFirstBScan:croppingLastBScan);
    bScanHeader.StartY = bScanHeader.StartY(croppingFirstBScan:croppingLastBScan);
    bScanHeader.EndX = bScanHeader.EndX(croppingFirstBScan:croppingLastBScan);
    bScanHeader.EndY = bScanHeader.EndY(croppingFirstBScan:croppingLastBScan);
    bScanHeader.NumSeg = bScanHeader.NumSeg(croppingFirstBScan:croppingLastBScan);
    bScanHeader.Quality = bScanHeader.Quality(croppingFirstBScan:croppingLastBScan);
    bScanHeader.Shift = bScanHeader.Shift(croppingFirstBScan:croppingLastBScan);
    bScanHeader.Version = bScanHeader.Version(:, croppingFirstBScan:croppingLastBScan);
    bScanHeader.BScanHdrSize = bScanHeader.BScanHdrSize(croppingFirstBScan:croppingLastBScan);
    bScanHeader.OffSeg = bScanHeader.OffSeg(croppingFirstBScan:croppingLastBScan);
    bScanHeader.Spare = bScanHeader.Spare(:, croppingFirstBScan:croppingLastBScan);
    
    %% Save the cropped volume
    % Write the cropped volume in the folder path given by user (if given)
    % or write it in a new folder named cropped in the volume directory.
    % Add '_cropped' to the end of the cropped volume
    [inputVolDir, inputVolName, inputVolExt] = fileparts(volPath);
    if nargin >= 3
        if ~isdir(varargin{3})
            mkdir(varargin{3})
        end
        croppedVolPath = [varargin{3}, '\', inputVolName, '_cropped', inputVolExt];
        write_vol(header, bScanHeader, sloImage, bScans, thicknessGrid, croppedVolPath);
    else
        if ~isdir([inputVolDir, '\cropped'])
            mkdir([inputVolDir, '\cropped']);
        end
        croppedVolPath = [inputVolDir, '\cropped\', inputVolName, '_cropped', inputVolExt];
        write_vol(header, bScanHeader, sloImage, bScans, thicknessGrid, croppedVolPath);
    end

catch ME
    if size(volumeFilesPath, 1) ~= 1
        % If an error happened just display the problematic volume name and
        % proceed
        disp(['Error  ', volPath]);
        disp(ME.message)
    else % In the case which there is only one volume to be segmented, the error should be managed by the program which called this function, not by this function itself
        rethrow(ME);
    end
end
end