function correct_segmentation_manual(volFilePath)
% This function opens a volume in the Octmaker program, receives the
% correction by user and overwrites it on the volume segmentation 
% 
% @param volFilePath The path to the vol file to be corrected
% 
% @author Seyedamirhosein Motamedi, Charité Universitätmedizin Berlin, October 2017
% 
% @usage correct_segmentation_manual('E:\data\EYE00123.vol');

%%
% Open the vol
[header, BScanHeader, slo, BScans, ThicknessGrid] = open_vol(volFilePath);

% Call Kay's manual correction program 
octMarkerPathSearch = what('octmarker64');
octMarkerPath = octMarkerPathSearch.path;
system(['"', octMarkerPath, '/octmarker.exe"  -i "', octMarkerPath, '/config.ini" --i-want-stupid-spline-gui "', volFilePath, '"']);

try
    % Read the correction
    manuallyCorrectedSegmentation = readbin([volFilePath, '.segmentation.bin']);
catch
    % In the case of an error, get out of the function since it is because
    % of the non-existing bin file which means that the user closed the
    % corrector witout saving
    return
end

% Overrrite the corrected segmentation to the vol file
BScanHeader.Boundary_1 = manuallyCorrectedSegmentation.ILM;
BScanHeader.Boundary_2 = manuallyCorrectedSegmentation.BM;
BScanHeader.Boundary_3 = manuallyCorrectedSegmentation.RNFL;
BScanHeader.Boundary_5 = manuallyCorrectedSegmentation.IPL;
BScanHeader.Boundary_6 = manuallyCorrectedSegmentation.INL;
BScanHeader.Boundary_7 = manuallyCorrectedSegmentation.OPL;
BScanHeader.Boundary_9 = manuallyCorrectedSegmentation.ELM;
BScanHeader.Boundary_15 = manuallyCorrectedSegmentation.PR1;
BScanHeader.Boundary_16 = manuallyCorrectedSegmentation.PR2;

% Write the vol file
write_vol(header, BScanHeader, slo, BScans, ThicknessGrid, volFilePath);

% Delete the manually correctesd segmentation seperate file (.bin file)
fclose('all');
delete([volFilePath, '.segmentation.bin']);

% Add '_corrected' to the end of the file name (if not included before)
if isempty(strfind(volFilePath, 'corrected'))
    % Parse the input vol file path
    [volFileDir, volFileName, volFileExt] = fileparts(volFilePath);
    
    % Rename the correted volume
    movefile(volFilePath, [volFileDir, '\', volFileName, '_corrected', volFileExt]);
end