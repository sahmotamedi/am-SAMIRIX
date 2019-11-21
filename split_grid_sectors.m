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

foveaBScan = header.NumBScans - (round(8*volumeFoveaYmm/header.Distance)/8);    % The number of the B-Scan which the fovea in located on it     %@note it is assumed that the center BScan is an interger plus 0, 1/2, 1/4 or 1/8. Zhis is set according to the centering process of cropping, and I cannot think of a case which it is an interger plus 1/16 or smaller
foveaAScan = header.SizeX - (round(2*volumeFoveaXmm/header.ScaleX)/2);          % The number of the A-Scan which the fovea in located on it     %@note it is assumed that the center AScan is either an interger number or and interger plus 1/2

% Check what type of grid is to be used 
if (isempty(varargin) || ~isempty(strfind(lower(varargin{1}), 'circ'))) % if the user did not pass any argument to determine the type of the grid or passed an argument included the key word 'circ', a circular grid is assusmed as the grid. 
    %% Split the volume according to a circular grid
    % Determine the radius of the grid circles 
    if (length(varargin) < 2) % if the user did not pass an argument to determine the outer diameter, the diametrers mentioned in thicknessGrid are considered as the grid diameters 
        centerRadius = thicknessGrid.Diameter(1)/2;
        innerRadius  = thicknessGrid.Diameter(2)/2;
        outerRadius  = thicknessGrid.Diameter(3)/2;
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
    centerSectorBScans = NaN(header.SizeZ, floor(2*centerRadius/header.ScaleX)+1, floor(2*centerRadius/header.Distance)+1);
    innerNasalSectorBScans = NaN(header.SizeZ, floor(2*innerRadius/sqrt(2)/header.ScaleX)+1, floor(innerRadius/header.Distance-centerRadius/sqrt(2)/header.Distance)+1);
    outerNasalSectorBScans = NaN(header.SizeZ, floor(2*outerRadius/sqrt(2)/header.ScaleX)+1, floor(outerRadius/header.Distance-innerRadius/sqrt(2)/header.Distance)+1);
    innerTemporalSectorBScans = innerNasalSectorBScans;
    outerTemporalSectorBScans = outerNasalSectorBScans;
    innerSuperiorSectorBScans = NaN(header.SizeZ, floor(innerRadius/header.ScaleX-centerRadius/sqrt(2)/header.ScaleX)+1, floor(2*innerRadius/sqrt(2)/header.Distance)+1);
    outerSuperiorSectorBScans = NaN(header.SizeZ, floor(outerRadius/header.ScaleX-innerRadius/sqrt(2)/header.ScaleX)+1, floor(2*outerRadius/sqrt(2)/header.Distance)+1);
    innerInferiorSectorBScans = innerSuperiorSectorBScans;
    outerInferiorSectorBScans = outerSuperiorSectorBScans;
    centerSectorSegmentation = NaN(size(segmentationData, 1), floor(2*centerRadius/header.ScaleX)+1, floor(2*centerRadius/header.Distance)+1);
    innerNasalSectorSegmentation = NaN(size(segmentationData, 1), floor(2*innerRadius/sqrt(2)/header.ScaleX)+1, floor(innerRadius/header.Distance-centerRadius/sqrt(2)/header.Distance)+1);
    outerNasalSectorSegmentation = NaN(size(segmentationData, 1), floor(2*outerRadius/sqrt(2)/header.ScaleX)+1, floor(outerRadius/header.Distance-innerRadius/sqrt(2)/header.Distance)+1);
    innerTemporalSectorSegmentation = innerNasalSectorSegmentation;
    outerTemporalSectorSegmentation = outerNasalSectorSegmentation;
    innerSuperiorSectorSegmentation = NaN(size(segmentationData, 1), floor(innerRadius/header.ScaleX-centerRadius/sqrt(2)/header.ScaleX)+1, floor(2*innerRadius/sqrt(2)/header.Distance)+1);
    outerSuperiorSectorSegmentation = NaN(size(segmentationData, 1), floor(outerRadius/header.ScaleX-innerRadius/sqrt(2)/header.ScaleX)+1, floor(2*outerRadius/sqrt(2)/header.Distance)+1);
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
                centerSectorBScans(:, floor(iAScan-foveaAScan+centerRadius/header.ScaleX)+1, floor(iBScan-foveaBScan+centerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                centerSectorSegmentation(:, floor(iAScan-foveaAScan+centerRadius/header.ScaleX)+1, floor(iBScan-foveaBScan+centerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
            elseif (centerRadius < thisAScanRho && thisAScanRho <= innerRadius) % Inner ring
                if (-pi/4 < thisAScanTheta && thisAScanTheta <= pi/4)
                    if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD - Inner Temporal
                        innerTemporalSectorBScans(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-centerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerTemporalSectorSegmentation(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-centerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Inner Nasal
                        innerNasalSectorBScans(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-centerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerNasalSectorSegmentation(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-centerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (pi/4 < thisAScanTheta && thisAScanTheta <= 3*pi/4) % Inner Superior
                    innerSuperiorSectorBScans(:, floor(iAScan-foveaAScan-centerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    innerSuperiorSectorSegmentation(:, floor(iAScan-foveaAScan-centerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                elseif ((3*pi/4 < thisAScanTheta && thisAScanTheta <= pi) || (-pi <= thisAScanTheta && thisAScanTheta <= -3*pi/4))
                    if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD - Inner Nasal
                        innerNasalSectorBScans(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerNasalSectorSegmentation(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Inner Temporal
                        innerTemporalSectorBScans(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        innerTemporalSectorSegmentation(:, floor(iAScan-foveaAScan+innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (-3*pi/4 < thisAScanTheta && thisAScanTheta <= -pi/4) % Inner Inferior
                    innerInferiorSectorBScans(:, floor(iAScan-foveaAScan+innerRadius/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    innerInferiorSectorSegmentation(:, floor(iAScan-foveaAScan+innerRadius/header.ScaleX)+1, floor(iBScan-foveaBScan+innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                end
            elseif (innerRadius < thisAScanRho && thisAScanRho <= outerRadius) % Outer ring
                if (-pi/4 < thisAScanTheta && thisAScanTheta <= pi/4)
                    if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD - Outer Temporal
                        outerTemporalSectorBScans(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerTemporalSectorSegmentation(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Outer Nasal
                        outerNasalSectorBScans(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-innerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerNasalSectorSegmentation(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan-innerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (pi/4 < thisAScanTheta && thisAScanTheta <= 3*pi/4) % Outer Superior
                    outerSuperiorSectorBScans(:, floor(iAScan-foveaAScan-innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    outerSuperiorSectorSegmentation(:, floor(iAScan-foveaAScan-innerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                elseif ((3*pi/4 < thisAScanTheta && thisAScanTheta <= pi) || (-pi <= thisAScanTheta && thisAScanTheta <= -3*pi/4))
                    if (~isempty(strfind(header.ScanPosition, 'OD')))   % OD - Outer Nasal
                        outerNasalSectorBScans(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerNasalSectorSegmentation(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    else % OS - Outer Temporal
                        outerTemporalSectorBScans(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/header.Distance)+1) = bScans(:, iAScan, iBScan);
                        outerTemporalSectorSegmentation(:, floor(iAScan-foveaAScan+outerRadius/sqrt(2)/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                    end
                elseif (-3*pi/4 < thisAScanTheta && thisAScanTheta <= -pi/4) % Outer Inferior
                    outerInferiorSectorBScans(:, floor(iAScan-foveaAScan+outerRadius/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/sqrt(2)/header.Distance)+1) = bScans(:, iAScan, iBScan);
                    outerInferiorSectorSegmentation(:, floor(iAScan-foveaAScan+outerRadius/header.ScaleX)+1, floor(iBScan-foveaBScan+outerRadius/sqrt(2)/header.Distance)+1) = segmentationData(:, iAScan, iBScan);
                end
            end
        end
    end
    
    % Form the sectors structure    
    % @note After testing this function, it turned out that these sector
    % calculations are correct only for vertical scans which are from right
    % to left, for other combinations like horizontal, and vertical from
    % left to right (different sloVolAngle other than between -pi/4 and
    % pi/4), the sector assigments are not correct, (e.g. innerNasal is
    % indeed innerSuperior in horizontal which is from buttom to up), so
    % this problem is corrected while the sectors structure is being formed
    if -pi/4 < sloVolumeAngle && sloVolumeAngle <= pi/4     % Vertical Right to Left
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
    elseif pi/4 < sloVolumeAngle && sloVolumeAngle <= 3*pi/4    % Horizontal Button to Top
        if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD
            sectors.centerSector.bScans = centerSectorBScans;
            sectors.innerNasalSector.bScans = innerSuperiorSectorBScans;
            sectors.outerNasalSector.bScans = outerSuperiorSectorBScans;
            sectors.innerTemporalSector.bScans = innerInferiorSectorBScans;
            sectors.outerTemporalSector.bScans = outerInferiorSectorBScans;
            sectors.innerSuperiorSector.bScans = innerTemporalSectorBScans;
            sectors.outerSuperiorSector.bScans = outerTemporalSectorBScans;
            sectors.innerInferiorSector.bScans = innerNasalSectorBScans;
            sectors.outerInferiorSector.bScans = outerNasalSectorBScans;
            sectors.centerSector.segmentation = centerSectorSegmentation;
            sectors.innerNasalSector.segmentation = innerSuperiorSectorSegmentation;
            sectors.outerNasalSector.segmentation = outerSuperiorSectorSegmentation;
            sectors.innerTemporalSector.segmentation = innerInferiorSectorSegmentation;
            sectors.outerTemporalSector.segmentation = outerInferiorSectorSegmentation;
            sectors.innerSuperiorSector.segmentation = innerTemporalSectorSegmentation;
            sectors.outerSuperiorSector.segmentation = outerTemporalSectorSegmentation;
            sectors.innerInferiorSector.segmentation = innerNasalSectorSegmentation;
            sectors.outerInferiorSector.segmentation = outerNasalSectorSegmentation;
        else  %OS
            sectors.centerSector.bScans = centerSectorBScans;
            sectors.innerNasalSector.bScans = innerInferiorSectorBScans;
            sectors.outerNasalSector.bScans = outerInferiorSectorBScans;
            sectors.innerTemporalSector.bScans = innerSuperiorSectorBScans;
            sectors.outerTemporalSector.bScans = outerSuperiorSectorBScans;
            sectors.innerSuperiorSector.bScans = innerNasalSectorBScans;
            sectors.outerSuperiorSector.bScans = outerNasalSectorBScans;
            sectors.innerInferiorSector.bScans = innerTemporalSectorBScans;
            sectors.outerInferiorSector.bScans = outerTemporalSectorBScans;
            sectors.centerSector.segmentation = centerSectorSegmentation;
            sectors.innerNasalSector.segmentation = innerInferiorSectorSegmentation;
            sectors.outerNasalSector.segmentation = outerInferiorSectorSegmentation;
            sectors.innerTemporalSector.segmentation = innerSuperiorSectorSegmentation;
            sectors.outerTemporalSector.segmentation = outerSuperiorSectorSegmentation;
            sectors.innerSuperiorSector.segmentation = innerNasalSectorSegmentation;
            sectors.outerSuperiorSector.segmentation = outerNasalSectorSegmentation;
            sectors.innerInferiorSector.segmentation = innerTemporalSectorSegmentation;
            sectors.outerInferiorSector.segmentation = outerTemporalSectorSegmentation;
        end
    elseif 3*pi/4 < sloVolumeAngle && sloVolumeAngle <= 5*pi/4  % Vertical Left to Right
        sectors.centerSector.bScans = centerSectorBScans;
        sectors.innerNasalSector.bScans = innerTemporalSectorBScans;
        sectors.outerNasalSector.bScans = outerTemporalSectorBScans;
        sectors.innerTemporalSector.bScans = innerNasalSectorBScans;
        sectors.outerTemporalSector.bScans = outerNasalSectorBScans;
        sectors.innerSuperiorSector.bScans = innerInferiorSectorBScans;
        sectors.outerSuperiorSector.bScans = outerInferiorSectorBScans;
        sectors.innerInferiorSector.bScans = innerSuperiorSectorBScans;
        sectors.outerInferiorSector.bScans = outerSuperiorSectorBScans;
        sectors.centerSector.segmentation = centerSectorSegmentation;
        sectors.innerNasalSector.segmentation = innerTemporalSectorSegmentation;
        sectors.outerNasalSector.segmentation = outerTemporalSectorSegmentation;
        sectors.innerTemporalSector.segmentation = innerNasalSectorSegmentation;
        sectors.outerTemporalSector.segmentation = outerNasalSectorSegmentation;
        sectors.innerSuperiorSector.segmentation = innerInferiorSectorSegmentation;
        sectors.outerSuperiorSector.segmentation = outerInferiorSectorSegmentation;
        sectors.innerInferiorSector.segmentation = innerSuperiorSectorSegmentation;
        sectors.outerInferiorSector.segmentation = outerSuperiorSectorSegmentation;
    elseif (5*pi/4 < sloVolumeAngle && sloVolumeAngle <= 3*pi/2) || (-pi/2 < sloVolumeAngle && sloVolumeAngle <= -pi/4)
        if (~isempty(strfind(header.ScanPosition, 'OD'))) % OD
            sectors.centerSector.bScans = centerSectorBScans;
            sectors.innerNasalSector.bScans = innerInferiorSectorBScans;
            sectors.outerNasalSector.bScans = outerInferiorSectorBScans;
            sectors.innerTemporalSector.bScans = innerSuperiorSectorBScans;
            sectors.outerTemporalSector.bScans = outerSuperiorSectorBScans;
            sectors.innerSuperiorSector.bScans = innerNasalSectorBScans;
            sectors.outerSuperiorSector.bScans = outerNasalSectorBScans;
            sectors.innerInferiorSector.bScans = innerTemporalSectorBScans;
            sectors.outerInferiorSector.bScans = outerTemporalSectorBScans;
            sectors.centerSector.segmentation = centerSectorSegmentation;
            sectors.innerNasalSector.segmentation = innerInferiorSectorSegmentation;
            sectors.outerNasalSector.segmentation = outerInferiorSectorSegmentation;
            sectors.innerTemporalSector.segmentation = innerSuperiorSectorSegmentation;
            sectors.outerTemporalSector.segmentation = outerSuperiorSectorSegmentation;
            sectors.innerSuperiorSector.segmentation = innerNasalSectorSegmentation;
            sectors.outerSuperiorSector.segmentation = outerNasalSectorSegmentation;
            sectors.innerInferiorSector.segmentation = innerTemporalSectorSegmentation;
            sectors.outerInferiorSector.segmentation = outerTemporalSectorSegmentation;
        else    % OS
            sectors.centerSector.bScans = centerSectorBScans;
            sectors.innerNasalSector.bScans = innerSuperiorSectorBScans;
            sectors.outerNasalSector.bScans = outerSuperiorSectorBScans;
            sectors.innerTemporalSector.bScans = innerInferiorSectorBScans;
            sectors.outerTemporalSector.bScans = outerInferiorSectorBScans;
            sectors.innerSuperiorSector.bScans = innerTemporalSectorBScans;
            sectors.outerSuperiorSector.bScans = outerTemporalSectorBScans;
            sectors.innerInferiorSector.bScans = innerNasalSectorBScans;
            sectors.outerInferiorSector.bScans = outerNasalSectorBScans;
            sectors.centerSector.segmentation = centerSectorSegmentation;
            sectors.innerNasalSector.segmentation = innerSuperiorSectorSegmentation;
            sectors.outerNasalSector.segmentation = outerSuperiorSectorSegmentation;
            sectors.innerTemporalSector.segmentation = innerInferiorSectorSegmentation;
            sectors.outerTemporalSector.segmentation = outerInferiorSectorSegmentation;
            sectors.innerSuperiorSector.segmentation = innerTemporalSectorSegmentation;
            sectors.outerSuperiorSector.segmentation = outerTemporalSectorSegmentation;
            sectors.innerInferiorSector.segmentation = innerNasalSectorSegmentation;
            sectors.outerInferiorSector.segmentation = outerNasalSectorSegmentation;
        end
    end
    
elseif ~isempty(strfind(lower(varargin{1}), 'square')) % if the grid type argument included the key word 'square', a square grid is assusmed as the grid

%%%%%%%%%%%%%% It has to be corrected for a non-integer center 
    
%     %% Split the volume according to a square grid
%     % Determine the size of the square and the grid
%     if length(varargin) == 1 % if the square and grid size parameters were not assigned
%         squareLengthAngle = 5;
%         gridLengthAngle = 20;
%     elseif length(varargin) == 2 % if only the square size parameter was assigned
%         squareLengthAngle = varargin{2};
%         gridLengthAngle = 20;
%     elseif length(varargin) == 3 % if both parameters were assigned 
%         squareLengthAngle = varargin{2};
%         gridLengthAngle = varargin{3};
%     end
%     
%     % Calculate the square length in the X direction (AScans) and the y
%     % direction (BScans), and also the number of squares in one direction
%     % (since the fovea is to be the center point of the grid, the square
%     % length (the number of BScans and AScans) and the number of squares in
%     % one direction have to be odd)
%     squareLengthX = 2*floor(header.SizeYSlo*header.ScaleYSlo/header.FieldSizeSlo*squareLengthAngle/header.ScaleX/2)+1;
%     squareLengthY = 2*floor(header.SizeXSlo*header.ScaleXSlo/header.FieldSizeSlo*squareLengthAngle/header.Distance/2)+1;
%     nSquares = 2*floor(gridLengthAngle/squareLengthAngle/2)+1;
%     
%     % Check if the length of the grid is greater than the size of the
%     % volume or not. If so, reduce the number of squares in one direction
%     % by 2 (has to be odd)
%     while nSquares*squareLengthX > header.SizeX || nSquares*squareLengthY > header.NumBScans
%         nSquares = nSquares - 2;
%     end
%     
%     % Split the volume 
%     centerSquareColumn = (nSquares + 1) / 2;
%     centerSquareRow = (nSquares + 1) / 2;
%     for iRow = 1:nSquares
%         for iColumn = 1:nSquares
%             sectors.(sprintf('squareSector%d%d', iRow, iColumn)).bScans = bScans(:, foveaAScan+ceil((iRow-centerSquareRow-0.5)*squareLengthX):foveaAScan+floor((iRow-centerSquareRow+0.5)*squareLengthX), foveaBScan+ceil((iColumn-centerSquareColumn-0.5)*squareLengthY):foveaBScan+floor((iColumn-centerSquareColumn+0.5)*squareLengthY));
%             sectors.(sprintf('squareSector%d%d', iRow, iColumn)).segmentation = segmentationData(:, foveaAScan+ceil((iRow-centerSquareRow-0.5)*squareLengthX):foveaAScan+floor((iRow-centerSquareRow+0.5)*squareLengthX), foveaBScan+ceil((iColumn-centerSquareColumn-0.5)*squareLengthY):foveaBScan+floor((iColumn-centerSquareColumn+0.5)*squareLengthY));
%         end
%     end
end