function thicknessProfile = calculate_thickness_profile(header, bScanHeader, bScans, thicknessGrid, iUpperBoundary, iLowerBoundary, thicknessProfileGridType)
% This function calculates the parameters related to the thickness of
% different boundaries of an OCT volumetric image
% 
% @params header, bScanHeader, bScans, thicknessGrid The information
% included in the OCT volume file
% 
% @params iUpperBoundary, iLowerBoundary The upper and lower boundaries
% which the thickness profile of the layer between them to be calculated
% 
% @note iUpperBoundary and iLowerBoundary are the numbers assigned to
% segmented boundaries by HeyEx e.g 1 for ILm, 2 for BM, 3 for RNFL and etc
% 
% @param thicknessProfileGridType The type of the circular grid for the
% thickness calculation which is the diameter of the outer circle
% 
% The thicknessProfileGridType parameter can be 6 (EDTRS), 3.45 or 3,
% other than these the EDTRS grid is assumed
% 
% @return thicknessProfile An structure consist of the thickness profile of
% each layer plus the total thickness. The structure and parameters for
% each layer is similar to the thickness grid
% 
% @author Seyedamirhosein Motamedi, Charite Universitätmedizin Berlin, November 2017
% 
% @usage thicknessProfile = calculate_thickness_profile(header, bScanHeader, bScans, thicknessGrid, 3, 5, 3.45);
% 

%%
% Combine the boundaries together and form the segmentation data 
segmentationData = cat(3, bScanHeader.Boundary_1, bScanHeader.Boundary_2);
for iBoundary = 3:bScanHeader.NumSeg(1)
    segmentationData = cat(3, segmentationData, bScanHeader.(sprintf('Boundary_%d', iBoundary)));
end
segmentationData = permute(segmentationData, [3, 2, 1]);

% Determine the radius of different circles based on the thicknessGridType 
switch thicknessProfileGridType
    case 6
        centerRadius = 0.5;
        innerRadius = 1.5;
        outerRadius = 3;
    case 3.45
        centerRadius = 0.5;
        innerRadius = 1.112;
        outerRadius = 1.725;
    case 3
        centerRadius = 0.5;
        innerRadius = 1;
        outerRadius = 1.5;
    otherwise % EDTRS if none of the above Grid type 
        thicknessProfileGridType = 6;
        centerRadius = 0.5;
        innerRadius = 1.5;
        outerRadius = 3;
end

% Form the sectors 
sectors = split_grid_sectors(header, bScanHeader, bScans, thicknessGrid, segmentationData, 'circ', thicknessProfileGridType);

% Calculate the area of the center circle and inner and outer sctors area
centerArea = centerRadius^2*pi;
innerSectorArea = (innerRadius^2-centerRadius^2)*pi/4;   
outerSectorArea = (outerRadius^2-innerRadius^2)*pi/4;  
sectorsAreas = [centerArea, innerSectorArea, outerSectorArea, innerSectorArea, outerSectorArea, innerSectorArea, outerSectorArea, innerSectorArea, outerSectorArea];

% Set the priori known information
thicknessProfile.Type = 3; % EDTRS
thicknessProfile.Diameter = [centerRadius*2; innerRadius*2; outerRadius*2];
thicknessProfile.CenterPos = thicknessGrid.CenterPos;

% Sort the sector names according to their appearence in the Sectors structure of the thickness profile (thickness grid)
if (~isempty(strfind(header.ScanPosition, 'OD')))
    sectorsNames = {'centerSector', 'innerNasalSector', 'outerNasalSector', 'innerSuperiorSector', 'outerSuperiorSector', 'innerTemporalSector', 'outerTemporalSector', 'innerInferiorSector', 'outerInferiorSector'};
else
    sectorsNames = {'centerSector', 'innerTemporalSector', 'outerTemporalSector', 'innerSuperiorSector', 'outerSuperiorSector', 'innerNasalSector', 'outerNasalSector', 'innerInferiorSector', 'outerInferiorSector'};
end

% Calculate the volume and thickness of each sector and the total volume
thisLayerTotalVolume = 0;
for iSector = 1:length(sectorsNames)
    thicknessProfile.Sectors(iSector).Thickness = sum(sum(sectors.(sectorsNames{iSector}).segmentation(iLowerBoundary, :, :) - sectors.(sectorsNames{iSector}).segmentation(iUpperBoundary, :, :), 'omitnan'), 'omitnan') / length(find(~isnan(sectors.(sectorsNames{iSector}).segmentation(iUpperBoundary, :, :)))) * header.ScaleZ;
    thicknessProfile.Sectors(iSector).Volume = thicknessProfile.Sectors(iSector).Thickness * sectorsAreas(iSector);
    thisLayerTotalVolume = thisLayerTotalVolume + thicknessProfile.Sectors(iSector).Volume;
end
thicknessProfile.TotalVolume = thisLayerTotalVolume;

% Determine the centralThk parameter
thicknessProfile.CentralThk = calculate_central_thickness(header, bScanHeader, thicknessGrid, segmentationData, iUpperBoundary, iLowerBoundary);

% Calculate the center min and max
thicknessProfile.MinCentralThk = nanmin(nanmin(sectors.centerSector.segmentation(iLowerBoundary, :, :) - sectors.centerSector.segmentation(iUpperBoundary, :, :))) * header.ScaleZ;
thicknessProfile.MaxCentralThk = nanmax(nanmax(sectors.centerSector.segmentation(iLowerBoundary, :, :) - sectors.centerSector.segmentation(iUpperBoundary, :, :))) * header.ScaleZ;
end

%% Calculate the central thickness
function centralThickness = calculate_central_thickness(header, bScanHeader, thicknessGrid, segmentationData, iUpperBoundary, iLowerBoundary)
% This function calulates the thickness at the fovea 
% 
% @params header, bScanHeader, thicknessGrid The information included in
% the vol file
% 
% @param segmentationData An array consists of all the segmentation data
% (different layers, all Bscans) together
% 
% @params iUpperBoundary, iLowerBoundary The upper and lower boundaries of the
% layer, which the central thickness is calculated
% 
% @return centralThickness The thickness at the fovea

% Find the B-Scan and the A-Scan which the fovea is located on from the fovea coordinate on the SLO image
sloFoveaXmm = thicknessGrid.CenterPos(1);   
sloFoveaYmm = thicknessGrid.CenterPos(2);   
sloVolumeAngle = atan((bScanHeader.EndY(1)-bScanHeader.EndY(end))/(bScanHeader.EndX(1)-bScanHeader.EndX(end))); % The angle between the SLO image and the volume grid on the SLO image plane

% Correct the angle if the actual angle is not between [-pi/2, pi/2] (atan output is always between -pi/2 and pi/2)
if bScanHeader.EndX(end) > bScanHeader.EndX(1)
    sloVolumeAngle = sloVolumeAngle + pi;
end
volumeFoveaYmm = (sloFoveaXmm-bScanHeader.EndX(end))*cos(sloVolumeAngle) + (sloFoveaYmm-bScanHeader.EndY(end))*sin(sloVolumeAngle);     
volumeFoveaXmm = -(sloFoveaXmm-bScanHeader.EndX(end))*sin(sloVolumeAngle) + (sloFoveaYmm-bScanHeader.EndY(end))*cos(sloVolumeAngle);    
foveaBScan = header.NumBScans - (round(volumeFoveaYmm/header.Distance));    
foveaAScan = header.SizeX - (round(volumeFoveaXmm/header.ScaleX));          

% Find the center and calculate the thickness 
centralThickness = (segmentationData(iLowerBoundary, foveaAScan, foveaBScan) - segmentationData(iUpperBoundary, foveaAScan, foveaBScan)) * header.ScaleZ;
end