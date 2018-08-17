function [] = MACKmeasure(parameters,parallel_flag)
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% [] = MACKmeasure(parameters,parallel_flag)
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
% MACKMEASURE calculates morphological features and optional
% additional-channel data from a MACKtrack output set.
%
% Takes in a MACKtrack output directory, loops through all xy positions,
% creating individual measurement sets (using the primarymeasure
% subfunction) for each.
% 
% At the end, it concatenates measurement sets into AllMeasurements 
% structure, which is saved in the output directory
%- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
if nargin<2
    parallel_flag = parameters.Parallel;
end

% Make directory names, list contents, initialize variables 
home_folder = mfilename('fullpath');
slash_idx = strfind(home_folder,filesep);
load([home_folder(1:slash_idx(end-1)), 'locations.mat'],'-mat')
parameters.locations = locations;
parameters.TotalImages = length(parameters.TimeRange);
% Record parameters before flatfield imgs are modified
AllMeasurements= struct;
AllMeasurements.parameters = parameters;

% Convert any parameter flatfield images to functions; add background image
if isfield(parameters,'Flatfield')
    parameters.Flatfield = processFlatfields(parameters.Flatfield);
end


% Outer loop: Cycle xy folders (in each condition)
if parallel_flag
    parfor i = 1:length(parameters.XYRange)
        xy = parameters.XYRange(i);
        measureLoop(xy,parameters)
    end % [end (xy) loop]
else
    for i = 1:length(parameters.XYRange)
        xy = parameters.XYRange(i);
        measureLoop(xy,parameters)
    end % [end (xy) loop]
end

% Cycle through XY directories and combine their measurements
for i = parameters.XYRange
    parameters.XYDir = namecheck([locations.data,filesep,parameters.SaveDirectory,filesep,'xy',num2str(i),filesep]);
    if exist([parameters.XYDir,'CellMeasurements.mat'],'file')
        load([parameters.XYDir,'CellMeasurements.mat'])
        measureFields = fieldnames(CellMeasurements);
        for p = 1:length(measureFields)
            if (isfield(AllMeasurements,measureFields{p}))
                AllMeasurements.(measureFields{p}) = cat(1, AllMeasurements.(measureFields{p}), CellMeasurements.(measureFields{p}));
            else
                AllMeasurements.(measureFields{p}) = CellMeasurements.(measureFields{p});
            end
        end        
    end
end % [end (xy) loop]


% Save AllMeasurements in condition directory. If we have trajectories for > 100K cells, save each field separately.
if size(AllMeasurements.CellData,1) < 1e5
    save(namecheck([locations.data, filesep, parameters.SaveDirectory,filesep,'AllMeasurements.mat']),'AllMeasurements','-v7.3')
else
    names = fieldnames(AllMeasurements);
    savedir = namecheck([locations.data, filesep, parameters.SaveDirectory,filesep,'AllMeasurements']);
    mkdir(savedir)
    for i =1:length(names)
        if isnumeric(AllMeasurements.(names{i}))
            eval([names{i}, '= single(AllMeasurements.(names{i}));'])
        else
            eval([names{i}, '= AllMeasurements.(names{i});'])
        end
        save([savedir, filesep, names{i}, '.mat'],names{i},'-v7.3')
        clear(names{i});
    end
end

