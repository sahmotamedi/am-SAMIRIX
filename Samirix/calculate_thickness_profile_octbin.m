function totalVolume = calculate_thickness_profile_octbin(volOCTbin, upperBoundary, lowerBoundary, thicknessProfileGridType, imageType)
% This function calculates the total volume for the octbin vol files
% 
% @param volOCTbin The volume in oct bin structure 
% 
% @params upperBoundary, lowerBoundary The upper and lower boundaries
% which the thickness profile of the layer between them to be calculated
% 
% @note upperBoundary and lowerBoundary must be names e.g. 'ILM', 'BM' etc
% 
% @param thicknessProfileGridType The type of the circular grid for the
% thickness calculation which is the diameter of the circle or if it is
% equal to 4.8 it means that the grid is Cirrus Annulus which is an
% ellipsoid annulus with the outer raius of 2.4, 2mm (the larger radius is
% in the horizontal direction) and inner raidus of 1.2 and 1 mm
% 
% @param imageType The type of the vOCT bin file which can be img (means
% that the octbin was converted from a img file) or fda (likewise)
% 
% @return totalVolume The total volume between upperBoundary and
% lowerBoundary in the determined circle or annulus
% 
% @author Seyedamirhosein Motamedi, Charite Universitätmedizin Berlin, July 2018
% 
% @usage totalVolume = calculate_thickness_profile_octbin(volOCTbin, 'ILM', 'BM', 6, 'fda OCT Bin')

%%
% Find the scaleX and distance between bscans (scaleY) by assuming the
% volume is 6*6mm
NumBScans = length(volOCTbin.serie);
SizeX = size(volOCTbin.serie{1,1}.img, 2);
SizeZ = size(volOCTbin.serie{1,1}.img, 1);
Distance = 6/(NumBScans-1);
ScaleX = 6/(SizeX-1);
if contains(imageType, 'fda')
    ScaleZ = 2.3/(SizeZ-1);
elseif contains(imageType, 'img')
    ScaleZ = 2/(SizeZ-1);
end
centerY = (NumBScans + 1)/2;
centerX = (SizeX + 1)/2;

% Combine the sgementations
for iBScan = 1:NumBScans
   upperBoundarySegmentation(iBScan, :) = volOCTbin.serie{1, iBScan}.segmentations.(upperBoundary);
   lowerBoundarySegmentation(iBScan, :) = volOCTbin.serie{1, iBScan}.segmentations.(lowerBoundary);
end

% Calculate the thickness 
thicknessMap = (lowerBoundarySegmentation - upperBoundarySegmentation)*ScaleZ;

if thicknessProfileGridType == 4.8 % Cirrus Annulus 
% The calculations here must be revised and retested before decommenting these lines. The problem comes with the asymmetricity of the annulus and the neccessity to find the oriention of Cirrus images, if they are vertical or horizontal 
%     for iBScan = 1:NumBScans
%         for iAScan = 1:SizeX
%             if (((iBScan-centerY)*Distance/2)^2 + ((iAScan-centerX)*ScaleX/2.4)^2) > 1 || (((iBScan-centerY)*Distance/0.5)^2 + ((iAScan-centerX)*ScaleX/0.6)^2) < 1              
%                 thicknessMap(iBScan, iAScan) = NaN;
%             end
%         end
%     end
    
else   % Circle 
    % Calculate the radius
    radius = thicknessProfileGridType / 2;
    
    % Replace the thickness values of the regions out of the roi with NaN
    for iBScan = 1:NumBScans
        for iAScan = 1:SizeX
            if (((iBScan-centerY)*Distance)^2 + ((iAScan-centerX)*ScaleX)^2) > radius^2
                thicknessMap(iBScan, iAScan) = NaN;
            end
        end
    end
end

% Calculate the average thickness
averageThickness = sum(sum(thicknessMap, 'omitnan'), 'omitnan') / length(find(~isnan(thicknessMap)));

% Calculate the total volume 
if thicknessProfileGridType == 4.8 % Cirrus Annulus 
    totalVolume = averageThickness * pi * (2*2.4 - 1*1.2);
else   % Circle     
    totalVolume = averageThickness * pi * radius^2;
end

