function write_vol(header, bScanHeader, sloImage, bScans, thicknessGrid, volumePath)
% @brief This function writes .vol file
% 
% The vol files written with this function has the exact same structure as
% the vol files written by the HEYEX software. The data sturcture was taken
% from the Spectralis documentation on exporing raw data
% 
% @params header, bScanHeader, sloImage, bScans, and thicknessGtid These
% parameters are the volume to be written and its related headers and
% information together with the slo image. 
% 
% The information about each of the above parameters can be found in the
% Spectralis documentation on exporting raw data.
% 
% @param volumePath The path included the file name and extension (*.vol)
% which the volume is writren to
% 
% @author Seyedamirhosein Motamedi, Charité Universitätmedizin Berlin, April 2017
% 
% @usage write_vol(header, bScanHeader, sloImage, bScans, thicknessGrid, 'C:\HE_Export\RAW\EYE01234.vol');

%% 
% open the file which the volume will be written in 
fileID = fopen(volumePath, 'w');

%% Write the header file 
fwrite(fileID, header.Version, 'int8');
fwrite(fileID, header.SizeX, 'int32');
fwrite(fileID, header.NumBScans, 'int32');
fwrite(fileID, header.SizeZ, 'int32');
fwrite(fileID, header.ScaleX, 'double');
fwrite(fileID, header.Distance, 'double');
fwrite(fileID, header.ScaleZ, 'double');
fwrite(fileID, header.SizeXSlo, 'int32');
fwrite(fileID, header.SizeYSlo, 'int32');
fwrite(fileID, header.ScaleXSlo, 'double');
fwrite(fileID, header.ScaleYSlo, 'double');
fwrite(fileID, header.FieldSizeSlo, 'int32');
fwrite(fileID, header.ScanFocus, 'double');
fwrite(fileID, header.ScanPosition, 'uint8');
fwrite(fileID, ((datenum(header.ExamTime)-datenum('1 January 1601 00:00:00'))*(1e7*60*60*24)), 'uint64');
fwrite(fileID, header.ScanPattern, 'int32');
fwrite(fileID, header.BScanHdrSize, 'int32');
fwrite(fileID, header.ID, 'uint8');
fwrite(fileID, header.ReferenceID, 'uint8');
fwrite(fileID, header.PID, 'int32');
fwrite(fileID, header.PatientID, 'uint8');
fwrite(fileID, header.Padding, 'int8');
fwrite(fileID, (datenum(header.DOB)-datenum('30 December 1899 00:00:00')), 'double');
fwrite(fileID, header.VID, 'int32');
fwrite(fileID, header.VisitID, 'uint8');
fwrite(fileID, (datenum(header.VisitDate)-datenum('30 December 1899 00:00:00')), 'double');
fwrite(fileID, header.GridType, 'int32');
fwrite(fileID, header.GridOffset, 'int32');
fwrite(fileID, header.Spare, 'int8');

%% Write the SLO
% Rotate the slo image to the orientation which the HEYEX saves a slo image
sloImage = flipud(sloImage);
sloImage = imrotate(sloImage, -90);

% Write the slo image
fseek(fileID, 2048, -1);
fwrite(fileID, sloImage, 'uint8');

%% Write the BScan 
for iBScan = 1:header.NumBScans
    % Write bScanHeader
    fseek(fileID, 2048+(header.SizeXSlo*header.SizeYSlo)+((iBScan-1)*(header.BScanHdrSize+header.SizeX*header.SizeZ*4)), -1);
    fwrite(fileID, bScanHeader.Version(:, iBScan), 'char');
    fwrite(fileID, bScanHeader.BScanHdrSize(iBScan), 'int32');
    fwrite(fileID, bScanHeader.StartX(iBScan), 'double' );
    fwrite(fileID, bScanHeader.StartY(iBScan), 'double' );  
    fwrite(fileID, bScanHeader.EndX(iBScan), 'double' );
    fwrite(fileID, bScanHeader.EndY(iBScan), 'double' );  
    fwrite(fileID, bScanHeader.NumSeg(iBScan), 'int32' );
    fwrite(fileID, bScanHeader.OffSeg(iBScan), 'int32' );
    fwrite(fileID, bScanHeader.Quality(iBScan), 'float32' );
    fwrite(fileID, bScanHeader.Shift(iBScan), 'int32' );
    fwrite(fileID, bScanHeader.Spare(:, iBScan), 'int8');
    
    % Write the segmentation data 
    fseek(fileID, 2048+(header.SizeXSlo*header.SizeYSlo)+((iBScan-1)*(header.BScanHdrSize+header.SizeX*header.SizeZ*4))+bScanHeader.OffSeg(iBScan), -1 );
    for iBoundary = 1:bScanHeader.NumSeg(iBScan)
        fwrite(fileID, bScanHeader.(sprintf('Boundary_%d', iBoundary))(iBScan, :), 'float');
    end
    
    % Fill the rest of bScanHeader with zero (int8)
    fillbytes = zeros(1, bScanHeader.BScanHdrSize(iBScan)-bScanHeader.OffSeg(iBScan)-bScanHeader.NumSeg(iBScan)*header.SizeX*4);
    fwrite(fileID, fillbytes, 'int8');
    
    % Rotate the BScan to the orientation which the HEYEX saves BScans
    thisBScan = bScans(:, :, iBScan);
    thisBScan = rot90(thisBScan);
    thisBScan = flipud(thisBScan);
    
    % Write B-Scan 
    fseek(fileID, 2048+header.SizeXSlo*header.SizeYSlo+(iBScan-1)*(header.BScanHdrSize+header.SizeX*header.SizeZ*4)+header.BScanHdrSize, -1 );
    fwrite(fileID, thisBScan, 'float32');
end

%% Write the Thickness Grid
if header.GridType ~= 0  % If the GridType is zero, there is no thickness information to be written
    fseek(fileID, header.GridOffset, -1);
    fwrite(fileID, thicknessGrid.Type, 'int32');
    fwrite(fileID, thicknessGrid.Diameter, 'double');
    fwrite(fileID, thicknessGrid.CenterPos, 'double');
    fwrite(fileID, thicknessGrid.CentralThk, 'float32');
    fwrite(fileID, thicknessGrid.MinCentralThk, 'float32');
    fwrite(fileID, thicknessGrid.MaxCentralThk, 'float32');
    fwrite(fileID, thicknessGrid.TotalVolume, 'float32');
    for i = 1:9
        fwrite(fileID, thicknessGrid.Sectors(i).Thickness, 'float32');
        fwrite(fileID, thicknessGrid.Sectors(i).Volume, 'float32');
    end
end

%%
% Close the file 
fclose(fileID);