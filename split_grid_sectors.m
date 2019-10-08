function [sectors] = split_grid_sectors(header, bScanHeader, bScans, thicknessGrid, segmentationData, varargin)
% @brief This function splits the input volume and its corresponding
% segmentation data according to a circular or square grid
% 
% @param header The header of the data
% 
% @param bScanHeader The header of the B-Scans 
% 
% @param bScans The B-Scans volumetric data
% 
% @param thicknessGrid The the thickness grid data
% 
% @param segmentationData The segmentaion data in pixels
% 
% @param varagin an input argument with different possible lengths
% determine the grid type and the related parameters The first element of
% varargin has to be an string indicating the type of the grid. If it
% contains the key word 'circ', the grid is to be circular and if 'square',
% the grid is to be square. If circular, the second element is the outer
% diameter which can be the numbers (6, 3.45, 3) or the string 'ETDRS'. If
% square, the second element is the length of the square in degree and the
% third element is the length of the grid in degree. If any of these
% parameters is missing, a default value is assumed for it. 
% 
% @return sectors The structure which contains the splitted vlumes and
% segmentation data divided according to the grid. The field names are the
% sectors names/numbers and each field of the structure contains two fields
% itself: bScans and segmentation
% 
% The circular grid is centered at the fovea and is divided to a center
% circle, four equally divided inner circular trapezoid (Nasal, temporal,
% superior and inferior) located between the center and inner circles and
% also four equally divided outer circular trapezoid located between the
% inner and outer circles. They are saved in the output structure according
% to their names (e.g. innerNasalSector)
% 
% The square grid is centered at the fovea. The volume is divided to equal
% numbers of square in the x and y directions. Each sector after division
% is stored in the output structure in the way that the sector 11 is the
% top left sector, the sector 12 is the sector left to the sector 11 in the
% Y direction, the sector 21 is the sector below it in the X direction and
% so on
% 
% @author Seyedamirhosein Motamedi, August 2016
% 
% sectors = split_grid_sectors(header, bScanHeader, bScans, thicknessGrid, segmentationData)

%% Find the B-Scan and the A-Scan which the fovea is located on from the fovea coordinate on the SLO image  
sloFoveaXmm = thicknessGrid.CenterPos(1);    % The position of the fovea in the horizontal direction in milimeters from the top left corner of the SLO image
sloFoveaYmm = thicknessGrid.CenterPos(2);    % The position of the fovea in the vertical direction in milimeters from the top left corner of the SLO image

sloVolumeAngle = atan((bScanHeader.EndY(1)-bScanHeader.EndY(end))/(bScanHeader.EndX(1)-bScanHeader.EndX(end))); % The angle between the SLO image and the volume grid on the SLO image plane 

% Correct the angle if the actual angle is not between [-pi/2, pi/2] (atan output is always between -pi/2 and pi/2)
if bScanHeader.EndX(end) > bScanHeader.EndX(1)
    sloVolumeAngle = sloVolumeAngle + pi;
end

volumeFoveaYmm = (sloFoveaXmm-bScanHeader.EndX(end))*cos(sloVolumeAngle) + (sloFoveaYmm-bScanHeader.EndY(end))*sin(sloVolumeAngle);     % The position of the fovea in the y direction in mm in the volume Grid (Note: the y direction in the volume is different from the y direction in the slo image)
volumeFoveaXmm = -(sloFoveaXmm-bScanHeader.EndX(end))*sin(sloVolumeAngle) + (sloFoveaYmm-bScanHeader.EndY(end))*cos(sloVolumeAngle);    % The position of the fovea in the x direction in mm in the volume Grid (Note: the x direction in the volume is different from the x direction in the slo image)

foveaBScan = header.NumBScans - (round(volumeFoveaYmm/header.Distance));    % The number of the B-Scan which the fovea in located on it 
foveaAScan = header.SizeX - (round(volumeFoveaXmm/header.ScaleX));          % The number of the A-Scan which the fovea in located on it 

% Check what type of grid is to be used 
if (isempty(varargin) || ~isempty(strfind(lower(varargin{1}), 'circ'))) % if the user did not pass any argument to determine the type of the grid or passed an argument included the key word 'circ', a circular grid is assusmed as the grid. 
    %% Split the volume according to a circular grid
    % Determine the radius of the grid circles 
    if (length(varargin) < 2) % if the user did not pass an argument to determine the outer diameter, the diametrers mentioned in thicknessGrid are considered as the grid diameters 
        centerRadius = thicknessGrid.Diameter(1)/2;
        innerRadius = thicknessGrid.Diameter(2)/2;
        outerRadius = thicknessGrid.Diameter(3)/2;
    else % in the case that the diameter parameter was given, the center, inner, and outer diameters are assigned accordingly 
        if ~isempty(find(varargin{2} == 6, 1)) || strcmpi(varargin{2}, 'ETDRS')
            centerRadius = 0.5; 
            innerRadius = 1.5; 
            outerRadius = 3;
        elseif varargin{2} == 3.45
            centerRadius = 0.5; 
            innerRadius = 1.112; 
            outerRadius = 1.725;
        elseif varargin{2} == 3
            centerRadius = 0.5; 
            innerRadius = 1; 
            outerRadius = 1.5;
        end
    end
    
    % Declare the matrices which hold the splitted volume and segmentation
    % (For each matrix, the minimum and maximum possible locations of
    % pixels belong to the corresponding sector in different directions are
    % used for the matrix size definition. In symmetric cases the matrix
    % was duplicated)
    centerSectorBScans = NaN(header.SizeZ, 2*floor(centerRadius/header.ScaleX)+1, 2*floor(centerRadius/header.Distance)+1);
    innerNasalSectorBScans = NaN(header.SizeZ, 2*floor(innerRadius/sqrt(2)/header.ScaleX)+1, floor(innerRadius/header.Distance)-ceil(centerRadius/sqrt(2)/header.Distance)+1);
    outerNasalSectorBScans = NaN(header.SizeZ, 2*floor(outerRadius/sqrt(2)/header.ScaleX)+1, floor(outerRadius/header.Distance)-ceil(innerRadius/sqrt(2)/header.Distance)+1);
    innerTemporalSectorBScans = innerNasalSectorBScans;
    outerTemporalSectorBScans = outerNasalSectorBScans;
    innerSuperiorSectorBScans = NaN(header.SizeZ, floor(innerRadius/header.ScaleX)-ceil(centerRadius/sqrt(2)/header.ScaleX)+1, 2*floor(innerRadius/sqrt(2)/header.Distance)+1);
    outerSuperiorSectorBScans = NaN(header.SizeZ, floor(outerRadius/header.ScaleX)-ceil(innerRadius/sqrt(2)/header.ScaleX)+1, 2*floor(outerRadius/sqrt(2)/header.Distance)+1);
    innerInferiorSectorBScans = innerSuperiorSectorBScans;
    outerInferiorSectorBScans = outerSuperiorSectorBScans;
    centerSectorSegmentation = NaN(size(segmentationData, 1), 2*floor(centerRadius/header.ScaleX)+1, 2*floor(centerRadius/header.Distance)+1);
    innerNasalSectorSegmentation = NaN(size(segmentationData, 1), 2*floor(innerRadius/sqrt(2)/header.ScaleX)+1, floor(innerRadius/header.Distance)-ceil(centerRadius/sqrt(2)/header.Distance)+1);
    outerNasalSectorSegmentation = NaN(size(segmentationData, 1), 2*floor(outerRadius/sqrt(2)/header.ScaleX)+1, floor(outerRadius/header.Distance)-ceil(innerRadius/sqrt(2)/header.Distance)+1);
    innerTemporalSectorSegmentation = innerNasalSectorSegmentation;
    outerTemporalSectorSegmentation = outerNasalSectorSegmentation;
    innerSuperiorSectorSegmentation = NaN(size(segmentationData, 1), floor(innerRadius/header.ScaleX)-ceil(centerRadius/sqrt(2)/header.ScaleX)+1, 2*floor(innerRadius/sqrt(2)/header.Distance)+1);
    outerSuperiorSectorSegmentation = NaN(size(segmentationData, 1), floor(outerRadius/header.ScaleX)-ceil(innerRadius/sqrt(2)/header.ScaleX)+1, 2*floor(outerRadius/sqrt(2)/header.Distance)+1);
    innerInferiorSectorSegmentation = innerSuperiorSectorSegmentation;
    outerInferiorSectorSegmentation = outerSuperiorSectorSegmentation;
    
    % Split the volume
    for iBScan = 1:header.NumBScans % go through the volume B-Scan by B-Scan and in each B-Scan A-Scan by A-Scan
        for iAScan = 1:header.SizeX
            % Find the A-Scan position in the polar coordinate system with
            % the fovea and x axis as the reference center and axis
            thisAScanX = (iAScan - foveaAScan) * header.ScaleX;
            thisAScanY = (iBScan - foveaBScan) * header.Distance;
            [thisAScanTheta, thisAScanRho] = cart2pol(thisAScanY, thisAScanX);
            
            % Find in which sector this AScan is located and then insert
            % the AScan and the segmentation data into the corresponding
            % volume and segmentation matrices (first from the theta and
            % rho of the A-Scan, the section which it is located in is
            % found (of course if it is inside any section) then the
            % location in the corresponding matrices is calculated and the
            % volumetric and segmentation data is inserted into the
            % matrices)
            if (thisAScanRho <= centerRadius) % Centeral Circle
                centerSectorBScans(:, iAScan-foveaAScan+floor(centerRadius/header.ScaleX)+1, iBScan-foveaBScan+floor(centerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                centerSectorSegmentation(:, iAScan-foveaAScan+floor(centerRadius/header.ScaleX)+1, iBScan-foveaBScan+floor(centerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
            elseif (centerRadius < thisAScanRho && thisAScanRho <= innerRadius) % Inner ring
                if (-pi/4 < thisAScanTheta && thisAScanTheta <= pi/4)
                    if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD - Inner Temporal
                        innerTemporalSectorBScans(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(centerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerTemporalSectorSegmentation(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(centerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Inner Nasal
                        innerNasalSectorBScans(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(centerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerNasalSectorSegmentation(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(centerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (pi/4 < thisAScanTheta && thisAScanTheta <= 3*pi/4) % Inner Superior
                    innerSuperiorSectorBScans(:, iAScan-foveaAScan-ceil(centerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    innerSuperiorSectorSegmentation(:, iAScan-foveaAScan-ceil(centerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                elseif ((3*pi/4 < thisAScanTheta && thisAScanTheta <= pi) || (-pi <= thisAScanTheta && thisAScanTheta <= -3*pi/4))
                    if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD - Inner Nasal
                        innerNasalSectorBScans(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerNasalSectorSegmentation(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Inner Temporal
                        innerTemporalSectorBScans(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerTemporalSectorSegmentation(:, iAScan-foveaAScan+floor(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (-3*pi/4 < thisAScanTheta && thisAScanTheta <= -pi/4) % Inner Inferior
                    innerInferiorSectorBScans(:, iAScan-foveaAScan+floor(innerRadius/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    innerInferiorSectorSegmentation(:, iAScan-foveaAScan+floor(innerRadius/header.ScaleX)+1, iBScan-foveaBScan+floor(innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                end
            elseif (innerRadius < thisAScanRho && thisAScanRho <= outerRadius) % Outer ring
                if (-pi/4 < thisAScanTheta && thisAScanTheta <= pi/4)
                    if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD - Outer Temporal
                        outerTemporalSectorBScans(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerTemporalSectorSegmentation(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Outer Nasal
                        outerNasalSectorBScans(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerNasalSectorSegmentation(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan-ceil(innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (pi/4 < thisAScanTheta && thisAScanTheta <= 3*pi/4) % Outer Superior
                    outerSuperiorSectorBScans(:, iAScan-foveaAScan-ceil(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    outerSuperiorSectorSegmentation(:, iAScan-foveaAScan-ceil(innerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                elseif ((3*pi/4 < thisAScanTheta && thisAScanTheta <= pi) || (-pi <= thisAScanTheta && thisAScanTheta <= -3*pi/4))
                    if (~isempty(strfind(header.ScanPosition, 'OD')))   % OD - Outer Nasal
                        outerNasalSectorBScans(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerNasalSectorSegmentation(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Outer Temporal
                        outerTemporalSectorBScans(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerTemporalSectorSegmentation(:, iAScan-foveaAScan+floor(outerRadius/sqrt(2)/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (-3*pi/4 < thisAScanTheta && thisAScanTheta <= -pi/4) % Outer Inferior
                    outerInferiorSectorBScans(:, iAScan-foveaAScan+floor(outerRadius/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    outerInferiorSectorSegmentation(:, iAScan-foveaAScan+floor(outerRadius/header.ScaleX)+1, iBScan-foveaBScan+floor(outerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                end
            end
        end
    end
    
    % Form the sectors structure
    sectors.centerSector.bScans = centerSectorBScans;
    sectors.innerNasalSector.bScans = innerNasalSectorBScans;
    sectors.outerNasalSector.bScans = outerNasalSectorBScans;
    sectors.innerTemporalSector.bScans = innerTemporalSectorBScans;
    sectors.outerTemporalSector.bScans = outerTemporalSectorBScans;
    sectors.innerSuperiorSector.bScans = innerSuperiorSectorBScans;
    sectors.outerSuperiorSector.bScans = outerSuperiorSectorBScans;
    sectors.innerInferiorSector.bScans = innerInferiorSectorBScans;
    sectors.outerInferiorSector.bScans = outerInferiorSectorBScans;
    sectors.centerSector.segmentation = centerSectorSegmentation;
    sectors.innerNasalSector.segmentation = innerNasalSectorSegmentation;
    sectors.outerNasalSector.segmentation = outerNasalSectorSegmentation;
    sectors.innerTemporalSector.segmentation = innerTemporalSectorSegmentation;
    sectors.outerTemporalSector.segmentation = outerTemporalSectorSegmentation;
    sectors.innerSuperiorSector.segmentation = innerSuperiorSectorSegmentation;
    sectors.outerSuperiorSector.segmentation = outerSuperiorSectorSegmentation;
    sectors.innerInferiorSector.segmentation = innerInferiorSectorSegmentation;
    sectors.outerInferiorSector.segmentation = outerInferiorSectorSegmentation;
    
elseif ~isempty(strfind(lower(varargin{1}), 'square')) % if the grid type argument included the key word 'square', a square grid is assusmed as the grid
    %% Split the volume according to a square grid 
    % Determine the size of the square and the grid
    if length(varargin) == 1 % if the square and grid size parameters were not assigned
        squareLengthAngle = 5;
        gridLengthAngle = 20;
    elseif length(varargin) == 2 % if only the square size parameter was assigned
        squareLengthAngle = varargin{2};
        gridLengthAngle = 20;
    elseif length(varargin) == 3 % if both parameters were assigned 
        squareLengthAngle = varargin{2};
        gridLengthAngle = varargin{3};
    end
    
    % Calculate the square length in the X direction (AScans) and the y
    % direction (BScans), and also the number of squares in one direction
    % (since the fovea is to be the center point of the grid, the square
    % length (the number of BScans and AScans) and the number of squares in
    % one direction have to be odd)
    squareLengthX = 2*floor(header.SizeYSlo*header.ScaleYSlo/header.FieldSizeSlo*squareLengthAngle/header.ScaleX/2)+1;
    squareLengthY = 2*floor(header.SizeXSlo*header.ScaleXSlo/header.FieldSizeSlo*squareLengthAngle/header.Distance/2)+1;
    nSquares = 2*floor(gridLengthAngle/squareLengthAngle/2)+1;
    
    % Check if the length of the grid is greater than the size of the
    % volume or not. If so, reduce the number of squares in one direction
    % by 2 (has to be odd)
    while nSquares*squareLengthX > header.SizeX || nSquares*squareLengthY > header.NumBScans
        nSquares = nSquares - 2;
    end
    
    % Split the volume 
    centerSquareColumn = (nSquares + 1) / 2;
    centerSquareRow = (nSquares + 1) / 2;
    for iRow = 1:nSquares
        for iColumn = 1:nSquares
            sectors.(sprintf('squareSector%d%d', iRow, iColumn)).bScans = bScans(:, foveaAScan+ceil((iRow-centerSquareRow-0.5)*squareLengthX):foveaAScan+floor((iRow-centerSquareRow+0.5)*squareLengthX), foveaBScan+ceil((iColumn-centerSquareColumn-0.5)*squareLengthY):foveaBScan+floor((iColumn-centerSquareColumn+0.5)*squareLengthY));
            sectors.(sprintf('squareSector%d%d', iRow, iColumn)).segmentation = segmentationData(:, foveaAScan+ceil((iRow-centerSquareRow-0.5)*squareLengthX):foveaAScan+floor((iRow-centerSquareRow+0.5)*squareLengthX), foveaBScan+ceil((iColumn-centerSquareColumn-0.5)*squareLengthY):foveaBScan+floor((iColumn-centerSquareColumn+0.5)*squareLengthY));
        end
    end
end