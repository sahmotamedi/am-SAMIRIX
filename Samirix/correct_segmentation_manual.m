function correct_segmentation_manual(volFilePath)
% This function opens a volume in the Octmaker program, receives the
% correction by user and overwrites it on the volume segmentation 
% 
% This function opens volumes in all formats acceptable by oct marker but
% only saves the corrected segmentation of octbin and vol files. Also, this
% fucntion only saves the correction of layers segmented by JHU
% segmentation
% 
% @param volFilePath The path to the vol file to be corrected
% 
% @author Seyedamirhosein Motamedi, Charité Universitätmedizin Berlin, October 2017
% 
% @usage correct_segmentation_manual('E:\data\EYE00123.vol');

%%
% Call Kay's manual correction program 
octMarkerPathSearch = what('octmarker64');
octMarkerPath = octMarkerPathSearch.path;
system(['"', octMarkerPath, '/octmarker.exe" --i-want-stupid-spline-gui "', volFilePath, '"']);

try
    % Read the correction
    manuallyCorrectedSegmentation = readbin([volFilePath, '.segmentation.bin']);
catch
    % In the case of an error, get out of the function since it is because
    % of the non-existing bin file which means that the user closed the
    % corrector witout saving
    return
end

% Delete the manually correctesd segmentation seperate file (.bin file)
fclose('all');
delete([volFilePath, '.segmentation.bin']);

% Split the file name parts
[volFileDir, volFileName, volFileExt] = fileparts(volFilePath);

if contains(volFileExt, 'vol') 
    % Open the vol
    [header, BScanHeader, slo, BScans, ThicknessGrid] = open_vol(volFilePath);
    
    % Replace NaNs with Heyex INVALID number
    INVALID = typecast(uint32(hex2dec('7f7fffff')),'single');
    manuallyCorrectedSegmentation.ILM(isnan(manuallyCorrectedSegmentation.ILM)) = INVALID;
    manuallyCorrectedSegmentation.BM(isnan(manuallyCorrectedSegmentation.BM)) = INVALID;
    manuallyCorrectedSegmentation.RNFL(isnan(manuallyCorrectedSegmentation.RNFL)) = INVALID;
    manuallyCorrectedSegmentation.GCL(isnan(manuallyCorrectedSegmentation.GCL)) = INVALID;
    manuallyCorrectedSegmentation.IPL(isnan(manuallyCorrectedSegmentation.IPL)) = INVALID;
    manuallyCorrectedSegmentation.INL(isnan(manuallyCorrectedSegmentation.INL)) = INVALID;
    manuallyCorrectedSegmentation.OPL(isnan(manuallyCorrectedSegmentation.OPL)) = INVALID;
    manuallyCorrectedSegmentation.ELM(isnan(manuallyCorrectedSegmentation.ELM)) = INVALID;
    manuallyCorrectedSegmentation.PR1(isnan(manuallyCorrectedSegmentation.PR1)) = INVALID;
    manuallyCorrectedSegmentation.PR2(isnan(manuallyCorrectedSegmentation.PR2)) = INVALID;
    manuallyCorrectedSegmentation.RPE(isnan(manuallyCorrectedSegmentation.RPE)) = INVALID;
    
    % Overrrite the corrected segmentation to the vol file
    BScanHeader.Boundary_1 = manuallyCorrectedSegmentation.ILM;
    BScanHeader.Boundary_2 = manuallyCorrectedSegmentation.BM;
    BScanHeader.Boundary_3 = manuallyCorrectedSegmentation.RNFL;
    BScanHeader.Boundary_4 = manuallyCorrectedSegmentation.GCL;
    BScanHeader.Boundary_5 = manuallyCorrectedSegmentation.IPL;
    BScanHeader.Boundary_6 = manuallyCorrectedSegmentation.INL;
    BScanHeader.Boundary_7 = manuallyCorrectedSegmentation.OPL;
    BScanHeader.Boundary_9 = manuallyCorrectedSegmentation.ELM;
    BScanHeader.Boundary_15 = manuallyCorrectedSegmentation.PR1;
    BScanHeader.Boundary_16 = manuallyCorrectedSegmentation.PR2;
    BScanHeader.Boundary_17 = manuallyCorrectedSegmentation.RPE;

elseif contains(volFileExt, 'octbin')
    % Open the octbin file 
    volOCTbin = readbin(volFilePath);
    
    % Write new segmentation on the OCTbin file 
    for iBscan = 1:length(volOCTbin.serie)
        volOCTbin.serie{1, iBscan}.segmentations.ILM = manuallyCorrectedSegmentation.ILM(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.RNFL = manuallyCorrectedSegmentation.RNFL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.GCL = manuallyCorrectedSegmentation.GCL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.IPL = manuallyCorrectedSegmentation.IPL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.INL = manuallyCorrectedSegmentation.INL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.OPL = manuallyCorrectedSegmentation.OPL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.ELM = manuallyCorrectedSegmentation.ELM(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.PR1 = manuallyCorrectedSegmentation.PR1(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.PR2 = manuallyCorrectedSegmentation.PR2(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.RPE = manuallyCorrectedSegmentation.RPE(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.BM = manuallyCorrectedSegmentation.BM(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.CHO = manuallyCorrectedSegmentation.CHO(iBscan, :);
    end
    
elseif contains(volFileExt, 'fda') || contains(volFileExt, 'img')       % The img does not have any segmentation included, but someone can draw segmentation lines in oct marker and this code saves that (just for fun)
    % Convert the fda file to octbin, and move it to a new folder named
    % after the fda or img file name (the converted octbin file does not
    % have the name inside)
    if contains(volFileExt, 'img')
        splittedVolFileName = strsplit(volFileName, '_');
        volFileDirTemp = [volFileDir, '/', splittedVolFileName{1}];
    else
        volFileDirTemp = [volFileDir, '/', volFileName];
    end
    if ~isdir(volFileDirTemp)
        mkdir(volFileDirTemp);
    end
    
    % Covert the fda file to oct bin (we save the segmentation of fda
    % alongside their volume data in octbin)
    system(['"', octMarkerPath, '/convert_oct_data.exe"  --outputPath="', volFileDirTemp, '/" -f octbin "', volFilePath, '"']);
    
    % Find the octbin file just created and chenge its name to the fda file
    % name, change the path to it 
    fileListSruct = dir(fullfile(volFileDirTemp, '*.octbin'));
    fileListCell = struct2cell(fileListSruct);
    octbinFilesList = fileListCell(1, :);
    if length(octbinFilesList) > 1 % if so, out of somewhere there is more than one octbin file in the folder, and we dont know which one is the correct, so throw an error 
        error(['There must be only one octbin file in this folder: ', volFileDirTemp]);
    end
    
    % Open the octbin file 
    volOCTbin = readbin([volFileDirTemp, '/', octbinFilesList{1}]);
    
    % Delete the folder 
    rmdir(volFileDirTemp, 's'); 
    
    % Write new segmentation on the OCTbin file 
    for iBscan = 1:length(volOCTbin.serie)
        volOCTbin.serie{1, iBscan}.segmentations.ILM = manuallyCorrectedSegmentation.ILM(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.RNFL = manuallyCorrectedSegmentation.RNFL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.GCL = manuallyCorrectedSegmentation.GCL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.IPL = manuallyCorrectedSegmentation.IPL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.INL = manuallyCorrectedSegmentation.INL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.OPL = manuallyCorrectedSegmentation.OPL(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.ELM = manuallyCorrectedSegmentation.ELM(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.PR1 = manuallyCorrectedSegmentation.PR1(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.PR2 = manuallyCorrectedSegmentation.PR2(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.RPE = manuallyCorrectedSegmentation.RPE(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.BM = manuallyCorrectedSegmentation.BM(iBscan, :);
        volOCTbin.serie{1, iBscan}.segmentations.CHO = manuallyCorrectedSegmentation.CHO(iBscan, :);
    end
    
    % Change the vol file extension to octbin
    if contains(volFileExt, 'fda')
        volFileExt = '_fda.octbin';
    elseif contains(volFileExt, 'img')
        volFileExt = '_img.octbin';
    end
    
end

% If the file to be corrected has _corrected inside, overrite on it,
% otherwise create a new folder named segmented and add _segmented to the
% end of the file name to be saved
if ~contains(volFileName, 'corrected')
    volFileDir = [volFileDir, '/corrected'];
    if ~isdir(volFileDir)
        mkdir(volFileDir);
    end
    volFilePath = [volFileDir, '/', volFileName, '_corrected', volFileExt];
else
    volFilePath = [volFileDir, '/', volFileName, volFileExt];
end

if contains(volFileExt, 'vol')
    % Write the vol file
    write_vol(header, BScanHeader, slo, BScans, ThicknessGrid, volFilePath);
    
elseif contains(volFileExt, 'octbin')
    % Write the octbin file 
    writebin(volFilePath, volOCTbin);
    
end
