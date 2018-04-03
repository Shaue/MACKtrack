function [CellMeasurements, ModuleData] = nucintensityModule(CellMeasurements, parameters, labels, AuxImages, ModuleData)
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% NUCINTENSITYMODULE measures nuclear intensities in AuxImages channel
%
% CellMeasurements    structure with fields corresponding to cell measurements
%
% parameters          experiment data (total cells, total images, output directory)
% labels              Cell,Nuclear label matricies (labels.Cell and labels.Nucleus)
% AuxImages           images to measure
% ModuleData          extra information (current iteration, etc.) used in measurement 
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
iteration  = ModuleData.iter;
measure_cc = label2cc(labels.Nucleus,0);

% Mode-balance 1st auxililiary image - unimodal distribution assumed
if ~isfield(ModuleData,'distr')
    [~, ModuleData.distr] = modebalance(AuxImages{1},1,ModuleData.BitDepth,'measure'); 
else
    AuxImages{1} = modebalance(AuxImages{1},1,ModuleData.BitDepth,'correct',ModuleData.distr);
end


% On first call, initialize all new CellMeasurements fields 
if ~isfield(CellMeasurements,'MeanIntensityNuc')
    % Intensity-based measurement initialization
    CellMeasurements.MeanIntensityNuc =  nan(parameters.TotalCells,parameters.TotalImages);
    CellMeasurements.IntegratedIntensityNuc =  nan(parameters.TotalCells,parameters.TotalImages);
    CellMeasurements.MedianIntensityNuc = nan(parameters.TotalCells,parameters.TotalImages);
end

% Cycle through each cell and assign measurements
for n = 1:measure_cc.NumObjects
    CellMeasurements.MeanIntensityNuc(n,iteration) = nanmean(AuxImages{1}(measure_cc.PixelIdxList{n}));
    CellMeasurements.IntegratedIntensityNuc(n,iteration) = nansum(AuxImages{1}(measure_cc.PixelIdxList{n}));
    CellMeasurements.MedianIntensityNuc(n,iteration) = nanmedian(AuxImages{1}(measure_cc.PixelIdxList{n}));
end


% Measure nuclei in 2nd auxiliary, if it is specified
if ~isempty(AuxImages{2})
    % Mode-balance
    if ~isfield(ModuleData,'distr2')
        [~, ModuleData.distr2] = modebalance(AuxImages{2},1,ModuleData.BitDepth,'measure'); 
    else
        AuxImages{2} = modebalance(AuxImages{2},1,ModuleData.BitDepth,'correct',ModuleData.distr2);
    end


    % On first call, initialize all new CellMeasurements fields 
    if ~isfield(CellMeasurements,'MeanIntensityNuc2')
        % Intensity-based measurement initialization
        CellMeasurements.MeanIntensityNuc2 =  nan(parameters.TotalCells,parameters.TotalImages);
        CellMeasurements.IntegratedIntensityNuc2 =  nan(parameters.TotalCells,parameters.TotalImages);
        CellMeasurements.MedianIntensityNuc2 = nan(parameters.TotalCells,parameters.TotalImages);
    end

    % Cycle through each cell and assign measurements
    for n = 1:measure_cc.NumObjects
        CellMeasurements.MeanIntensityNuc2(n,iteration) = nanmean(AuxImages{2}(measure_cc.PixelIdxList{n}));
        CellMeasurements.IntegratedIntensityNuc2(n,iteration) = nansum(AuxImages{2}(measure_cc.PixelIdxList{n}));
        CellMeasurements.MedianIntensityNuc2(n,iteration) = nanmedian(AuxImages{2}(measure_cc.PixelIdxList{n}));
    end

end
