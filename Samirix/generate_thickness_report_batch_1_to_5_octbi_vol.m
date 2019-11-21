function generate_thickness_report_batch_1_to_5_octbi_vol(volFilesPathList, upperBoundary, lowerBoundary, reportSavingPath)

%%
% Open the report saving file
fileID = fopen(reportSavingPath, 'w');

% Write the header
fprintf(fileID, 'Lastname,Eye,ExamDate,ImageType,Upper Layer,Lower Layer,GridType,Average Thickness [µm],TotalVolume [mm³],Fovea ASscan,Fovea BScan,note\n');

% Creat a wait bar
handleWaitBar = waitbar(0, 'Exporting thickness profiles! Please wait...');

% Form the thickness table and then write it in the report file volume by volume
for iVolume = 1:length(volFilesPathList)
    try
        if contains(volFilesPathList{iVolume}, '.vol') || (contains(volFilesPathList{iVolume}, '_img') && contains(volFilesPathList{iVolume}, '.octbin')) || (contains(volFilesPathList{iVolume}, '_fda') && contains(volFilesPathList{iVolume}, '.octbin'))
            % Define the thickness profile report table
            thicknessProfileReportTable = table;
            
            % Split the volfile path so we can use the vol file name later
            [~, volFileName, ~] = fileparts(volFilesPathList{iVolume});
            
            if contains(volFilesPathList{iVolume}, '.vol') % if it is a spectralis vol file
                % Read the vol file
                [header, bScanHeader, ~, ~, ~] = open_vol(volFilesPathList{iVolume});
                
                % Form the thickness profile report table
                thicknessProfileReportTable.LastName{1} = volFileName;      % here the volfile name is given to the last name in case that the vol file is fully anonymized, in which there is no eye id as well
                thicknessProfileReportTable.Eye = latin2englishEyePos(deblank(header.ScanPosition));
                thicknessProfileReportTable.ExamDate = datestr(datenum(header.ExamTime(1:11)), 'dd.mm.yyyy');
                thicknessProfileReportTable.ImageType = {'Spectralis OCT Volume Scan'};
                
                % Check if the upper boundary and lower boundary have been segmented
                iUpperBoundary = findBoundary(upperBoundary, header, bScanHeader);
                iLowerBoundary = findBoundary(lowerBoundary, header, bScanHeader);                    
                if isempty(iUpperBoundary) || isempty(iLowerBoundary) % if boundaries are not segmented, write the table in the report file and complete the thickness related parameters with blank and go to the next iteration 
                    thicknessProfileReportTable.UpperLayer = upperBoundary;
                    thicknessProfileReportTable.LowerLayer = lowerBoundary;
                    thicknessProfileReportTable.GridType = '1-5mm Doughnut with centering';
                    thicknessProfileReportTable.note = 'The segmentation of one or both boundaries were not found';
                    thicknessProfileReportCell = table2cell(thicknessProfileReportTable);
                    fprintf(fileID, '%s,%s,%s,%s,%s,%s,%s,,,,,%s\n', thicknessProfileReportCell{:});
                    continue
                end
                
                % Define the parameters for thickness calculation 
                ILMSegmentation = bScanHeader.Boundary_1;
                BMSegmentation = bScanHeader.Boundary_2;
                upperBoundarySegmentation = eval(['bScanHeader.Boundary_', num2str(iUpperBoundary), ';']);
                lowerBoundarySegmentation = eval(['bScanHeader.Boundary_', num2str(iLowerBoundary), ';']);
                nBScans = header.NumBScans;
                nAScans = header.SizeX;
                sizeZ = header.SizeZ;
                distanceBScans = header.Distance;
                distanceAScans = header.ScaleX;
                scaleZ = header.ScaleZ;
                
            elseif contains(volFilesPathList{iVolume}, '.octbin')
                % Read the OCT bin
                volOCTbin = readbin(volFilesPathList{iVolume});
                
                % Form the thickness profile report table 
                thicknessProfileReportTable.LastName{1} = volFileName;      % here the volfile name is given to the last name in case that the vol file is fully anonymized, in which there is no eye id as well
                
                % Determine the laterality, exam date and time and the image type
                if contains(volFileName, '_fda')
                    thicknessProfileReportTable.Eye = latin2englishEyePos(deblank(volOCTbin.seriesData.laterality));
                    thicknessProfileReportTable.ExamDate = datestr(datenum(volOCTbin.seriesData.scanDate(1:10), 'YYYY.MM.DD'), 'DD.MM.YYYY');
                    thicknessProfileReportTable.ImageType = {'fda OCT Bin'};
                elseif contains(volFileName, '_img')
                    splittedVolFileName = strsplit(volFileName, '_');
                    thicknessProfileReportTable.Eye = latin2englishEyePos(deblank(splittedVolFileName{5}));
                    thicknessProfileReportTable.ExamDate = datestr(datenum(splittedVolFileName{3}, 'MM-DD-YYYY'), 'DD.MM.YYYY');
                    thicknessProfileReportTable.ImageType = {'img OCT Bin'};
                end
                
                % Check if the upper and lower boundaries have been
                % segmented
                isSegmentationCompleteFlag = 1;
                for iBscan = 1:length(volOCTbin.serie)
                    if ~isfield(volOCTbin.serie{1, iBscan}.segmentations, upperBoundary) || ~isfield(volOCTbin.serie{1, iBscan}.segmentations, lowerBoundary)
                        isSegmentationCompleteFlag = 0;
                    else
                        if length(find(isnan(volOCTbin.serie{1, iBscan}.segmentations.(upperBoundary)))) == size(volOCTbin.serie{1,iBscan}.img, 2) || length(find(isnan(volOCTbin.serie{1, iBscan}.segmentations.(lowerBoundary)))) == size(volOCTbin.serie{1,iBscan}.img, 2)  % if the segmentation for one BScan is totally missing then it is assumed that that layer is not properly segmented
                            isSegmentationCompleteFlag = 0;
                        end
                    end
                end 
                    
                if isSegmentationCompleteFlag == 0 % if boundaries are not segmented, write the table in the report file and complete the thickness related parameters with blank and go tot the next iteration 
                    thicknessProfileReportTable.UpperLayer = upperBoundary;
                    thicknessProfileReportTable.LowerLayer = lowerBoundary;
                    thicknessProfileReportTable.GridType = '1-5mm Doughnut with centering';
                    thicknessProfileReportTable.note = 'The segmentation of one or both boundaries were not found';
                    thicknessProfileReportCell = table2cell(thicknessProfileReportTable);
                    fprintf(fileID, '%s,%s,%s,%s,%s,%s,%s,,,,,%s\n', thicknessProfileReportCell{:});
                    continue
                end
                
                % Find the scaleX and distance between bscans (scaleY) by assuming the
                % volume is 6*6mm
                nBScans = length(volOCTbin.serie);
                nAScans = size(volOCTbin.serie{1,1}.img, 2);
                sizeZ = size(volOCTbin.serie{1,1}.img, 1);
                distanceBScans = 6/(nBScans-1);
                distanceAScans = 6/(nAScans-1);
                if contains(volFileName, '_fda')
                    scaleZ = 2.3/(sizeZ-1);
                elseif contains(volFileName, '_img')
                    scaleZ = 2/(sizeZ-1);
                end
                ILMSegmentation = [];
                BMSegmentation = [];
                upperBoundarySegmentation = [];
                lowerBoundarySegmentation = [];
                for iBScan = 1:nBScans
                    ILMSegmentation(iBScan, :) = volOCTbin.serie{1, iBScan}.segmentations.ILM;
                    BMSegmentation(iBScan, :) = volOCTbin.serie{1, iBScan}.segmentations.BM;
                    upperBoundarySegmentation(iBScan, :) = volOCTbin.serie{1, iBScan}.segmentations.(upperBoundary);
                    lowerBoundarySegmentation(iBScan, :) = volOCTbin.serie{1, iBScan}.segmentations.(lowerBoundary);
                end
                
                % Replace NaNs in the segmentation with INVALID number of
                % spectralis so if there is a segmentation line missing
                % inside our region of interest it will result in a big
                % number in the next steps which we can take care of later
                INVALID = typecast(uint32(hex2dec('7f7fffff')),'single');
                ILMSegmentation(isnan(ILMSegmentation)) = INVALID;
                BMSegmentation(isnan(BMSegmentation)) = INVALID;
                upperBoundarySegmentation(isnan(upperBoundarySegmentation)) = INVALID;
                lowerBoundarySegmentation(isnan(lowerBoundarySegmentation)) = INVALID;
            end
            
            %%%%% We can be sure that if the code reaches this point, the
            %%%%% upper and lower boundaries are sgemented, and
            %%%%% additionally it is asssumed that the ILM and BM are
            %%%%% always segemented
            % Continue to fill the report table with thickness profile information
            thicknessProfileReportTable.UpperLayer = upperBoundary;
            thicknessProfileReportTable.LowerLayer = lowerBoundary;
            thicknessProfileReportTable.GridType = '1-5mm Doughnut with centering';
            
            % find the center 
            [foveaBScanAuto, foveaAScanAuto] = find_center(ILMSegmentation, BMSegmentation, distanceBScans, distanceAScans, scaleZ, volFileName);
            
            % Check if the 5 mm circle around the fovea fits to the volume,
            % if not write in the notes and continue
            if foveaBScanAuto*distanceBScans < 2.5 || (nBScans-foveaBScanAuto+1) < 2.5 || foveaAScanAuto*distanceAScans < 2.5 || (nAScans-foveaAScanAuto+1) < 2.5
                thicknessProfileReportTable.note = 'The volume does not fit into a 5mm circle around the fovea';
                thicknessProfileReportCell = table2cell(thicknessProfileReportTable);
                fprintf(fileID, '%s,%s,%s,%s,%s,%s,%s,,,,,%s\n', thicknessProfileReportCell{:});
                continue
            end
            
            % Calculate the thickness
            thicknessMap = (lowerBoundarySegmentation - upperBoundarySegmentation)*scaleZ;
            
            % Replace the thickness values of the regions out of the roi with NaN
            for iBScan = 1:nBScans
                for iAScan = 1:nAScans
                    if (((iBScan-foveaBScanAuto)*distanceBScans)^2 + ((iAScan-foveaAScanAuto)*distanceAScans)^2) > 2.5^2 || (((iBScan-foveaBScanAuto)*distanceBScans)^2 + ((iAScan-foveaAScanAuto)*distanceAScans)^2) < 0.5^2
                        thicknessMap(iBScan, iAScan) = NaN;
                    end
                end
            end
            
            % Calculate the average thickness
            averageThickness = sum(sum(thicknessMap, 'omitnan'), 'omitnan') / length(find(~isnan(thicknessMap)));
            if abs(averageThickness) > 10 % this checks if there was an invalid number in the segmentation (I chose 10 arbitrarily, the INVALID number is big enough that any threshhold between 1 to 10e32 does the job)
                thicknessProfileReportTable.note = 'The segmentation for one of the layers or both is missing in the region of interest';
                thicknessProfileReportCell = table2cell(thicknessProfileReportTable);
                fprintf(fileID, '%s,%s,%s,%s,%s,%s,%s,,,,,%s\n', thicknessProfileReportCell{:});
                continue
            end
            
            % Assign the average thickness
            thicknessProfileReportTable.averageThickness = averageThickness * 1000;
            
%             % Calculate the center thickness
%             thicknessProfileReportTable.centerThickness = (lowerBoundarySegmentation(round(foveaBScanAuto), round(foveaAScanAuto)) - upperBoundarySegmentation(round(foveaBScanAuto), round(foveaAScanAuto))) * scaleZ * 1000;
            
            % Calculate the total volume
            thicknessProfileReportTable.TotalVolume = averageThickness * (2.5^2-0.5^2) * pi;
            
            % Add fovea AScan and BScan to the table
            thicknessProfileReportTable.FoveaAScan = foveaAScanAuto;
            thicknessProfileReportTable.FoveaBScan = foveaBScanAuto;

            % Convert the table to a cell and then write it in the report file
            thicknessProfileReportCell = table2cell(thicknessProfileReportTable);
            fprintf(fileID, '%s,%s,%s,%s,%s,%s,%s,%.2f,%.3f,%.1f,%.1f,\n', thicknessProfileReportCell{:});
        else
            [~, volFileName, volFileExt] = fileparts(volFilesPathList{iVolume});
            fprintf(fileID, '%s,,,,,,,,,,,Unacceptable file type: %s\n', volFileName, volFileExt);
            continue
        end
        
        % Update the wait bar
        waitbar(iVolume/length(volFilesPathList));
        
    catch ME
        % Write only the volume name if an error happened in thickness
        % calculation and go on
        [~, volFileName, ~] = fileparts(volFilesPathList{iVolume});
        fprintf(fileID, '%s,,,,,,,,,,,An error occured while handling the thickness calculation for this volume. Error message: %s\n', volFileName, ME.message);
        continue
    end
end

% Close the wait bar
close(handleWaitBar);

% Close the file
fclose(fileID);
end

%%
function iBoundary = findBoundary(boundaryName, header, bScanHeader)
% This function checks if a boundary is present in the segmentation and
% also converts the segmented layer name to the number of the segmented
% layer in the bScanHeader
% 
% @param boundaryName The name of the boundary to be checked 
% 
% @param header, bScanHeader The vol file header files 
% 
% @return iBoundary The number of the boundary if segmented, if not empty
% array is returned 
% 
% @usage iBoundary = findBoundary('RNFL', header, bScanHeader)

% Take the number of the boundary (if the name is valid)
switch boundaryName
    case 'ILM'
        iBoundary = 1;
    case 'BM'
        iBoundary = 2;
    case 'RNFL'
        iBoundary = 3;
    case 'GCL'
        iBoundary = 4;
    case 'IPL'
        iBoundary = 5;
    case 'INL'
        iBoundary = 6;
    case 'OPL'
        iBoundary = 7;
    case 'ELM'
        iBoundary = 9;
    case 'PR1'
        iBoundary = 15;
    case 'PR2'
        iBoundary = 16;
    case 'RPE'
        iBoundary = 17;
    otherwise
        iBoundary = [];
end

% Check if that layer has been segmented
if iBoundary 
   INVALID = typecast(uint32(hex2dec('7f7fffff')),'single');
   if isfield(bScanHeader, sprintf('Boundary_%d', iBoundary)) % if exist
       if length(find(bScanHeader.(sprintf('Boundary_%d', iBoundary)) == INVALID)) == header.SizeX*header.NumBScans
           iBoundary = [];
       end
   else 
       iBoundary = [];
   end
end
end 

%%
function eyePosEng = latin2englishEyePos(eyePosLat)
% This function converts the eye position from Latin to Englis (OS OD to R
% L)
% 
% @param eyePosLat The eye position in Latin (either OD or OS)
% 
% @return eyePosEng The eye position in English (R or L)

if strcmpi(deblank(eyePosLat), 'OD')
    eyePosEng = 'R';
elseif strcmpi(deblank(eyePosLat), 'OS')
    eyePosEng =  'L';
end
end

%%
function [foveaBScanAuto, foveaAScanAuto] = find_center(ILMSegmentation, BMSegmentation, distanceBScans, distanceAScans, scaleZ, volFileName)

% Create relative surface
ILMrelFull = BMSegmentation - ILMSegmentation;
ILMrelFull = ILMrelFull * scaleZ;  % We consider the scale

% Get the region of 2mm around (1mm from left, right, top and bottom) the
% center. It is assumed that the fovea is in 1mm distance around the
% geometrical center of the image (if it is cropped for sure it will be.
% For Topcon and Cirrus this should fine as well I guess)
distBScans2mm = round(1/distanceBScans);
distAScans2mm = round(1/distanceAScans);
foveaBScanMan = round(size(ILMSegmentation, 1)/2);
foveaAScanMan = round(size(ILMSegmentation, 2)/2);
marginLeftBScans2mm  = foveaAScanMan - distAScans2mm;
marginRightBScans2mm = foveaAScanMan + distAScans2mm;
startBScans2mm       = foveaBScanMan - distBScans2mm;
endBScans2mm         = foveaBScanMan + distBScans2mm;

% Search for the minimum point in the 2mm area near the manually determined
% fovea (and call it automatically determined fovea point)
minSearchRegion2mm = ILMrelFull(startBScans2mm:endBScans2mm,marginLeftBScans2mm:marginRightBScans2mm);
% Check if the INVALID number exists in any of the points in this region 
if abs(sum(sum(minSearchRegion2mm)) / size(minSearchRegion2mm,1) / size(minSearchRegion2mm, 2)) > 10 % Through an error if this is true
    error('There is missing ILM or/and BM segmentation points in the region that the program look for the fovea!')
end
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

% Take out the 1mm square around the automatic center
distBScans1mm = round(0.5/distanceBScans);
distAScans1mm = round(0.5/distanceAScans);
onemmSquareAroundCenter = ILMrelFull((foveaBScanAuto-distBScans1mm):(foveaBScanAuto+distBScans1mm), (foveaAScanAuto-distAScans1mm):(foveaAScanAuto+distAScans1mm));
% Check if the INVALID number exists in any of the points in this region 
if abs(sum(sum(onemmSquareAroundCenter)) / size(onemmSquareAroundCenter,1) / size(onemmSquareAroundCenter, 2)) > 10 % Through an error if this is true
    error('There is missing ILM or/and BM segmentation points in the region that the program look for the fovea!')
end

% Form the meshgrid for the surface fitting (the automatically found center
% has the coordiante of [0,0]
[AScanGrid,BScanGrid] = meshgrid((-distAScans1mm):(distAScans1mm), (-distBScans1mm):(distBScans1mm));
BScanGrid = BScanGrid * distanceBScans;
AScanGrid = AScanGrid * distanceAScans;

% Fit the surface
fittedSurface = fit([reshape(BScanGrid, [], 1),reshape(AScanGrid, [], 1)], reshape(onemmSquareAroundCenter, [], 1), 'poly44');

% % Plot the surface togehter with the original data
% figure('name', volFileName)
% plot(fittedSurface, [reshape(BScanGrid, [], 1),reshape(AScanGrid, [], 1)], reshape(onemmSquareAroundCenter, [], 1))

% Determine the number of BScans and AScans to be added virtually
virtualBScans = 1;
virtualAScans = 1;

% Form the sampling grid. Each step around 12 micron would be fine. At the
% end, the number of virtual BScans and AScans matter
samplingRateAScans = round(distanceAScans/0.012);
samplingRateBScans = round(distanceBScans/0.012);
[reSamplingAScanGrid,reSamplingBScanGrid] = meshgrid((-distAScans1mm)*(virtualAScans+1)*(samplingRateAScans+1):(distAScans1mm)*(virtualAScans+1)*(samplingRateAScans+1), (-distBScans1mm*(virtualBScans+1)*(samplingRateBScans+1)):(distBScans1mm*(virtualBScans+1)*(samplingRateBScans+1)));
reSamplingAScanGrid = reSamplingAScanGrid * distanceAScans/((virtualAScans+1)*(samplingRateAScans+1));
reSamplingBScanGrid = reSamplingBScanGrid * distanceBScans/((virtualBScans+1)*(samplingRateBScans+1));

% Find the minimum point of the fitted surface and find the min point
% displacement from the center found above
[fitMinPointBScan, fitMinPointAScan] = ind2sub(size(fittedSurface(reSamplingBScanGrid, reSamplingAScanGrid)), find(fittedSurface(reSamplingBScanGrid, reSamplingAScanGrid) == min(min(fittedSurface(reSamplingBScanGrid, reSamplingAScanGrid))), 1));
centerDisplacementBScanDirMm = reSamplingBScanGrid(fitMinPointBScan, 1);
centerDisplacementAScanDirMm = reSamplingAScanGrid(1, fitMinPointAScan);

% Shift the automatic center according to the displacement. Only half and
% complete AScan/BScan shift is allowed, so we are going zo round
foveaBScanAuto = foveaBScanAuto + round((virtualBScans+1)*(centerDisplacementBScanDirMm/distanceBScans))/(virtualBScans+1);
foveaAScanAuto = foveaAScanAuto + round((virtualAScans+1)*(centerDisplacementAScanDirMm/distanceAScans))/(virtualAScans+1);

end
