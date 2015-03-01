function [observations] = generateObservations(do_save)
% GENERATEOBSERVATIONS Generate observations by prompting user to select
% dataset directory.
% 
if nargin < 1, do_save = false; end

% Load dataset
dataset_path = uigetdir('', 'Select dataset directory');
if ~dataset_path
    error('No dataset selected');
end
dataset = Dataset(dataset_path);

% Load descriptors
%[descriptors_file, descriptors_path] = uigetfile('*.mat', ...
 %                                                'Select descriptor file');
%if ~descriptors_file
%    error('No descriptors selected');
%end
%descriptors = load([descriptors_path, descriptors_file]);
%descriptors = descriptors.descriptors;

%applyDescriptors(dataset.images{i}, descriptors{1});

scale = 0.5;
maxRatio = 5;
observations = extractObservations(dataset, @(x)someCallback(x),...
    'scale', scale, 'maxRatio', maxRatio);

% Save descriptors
if do_save
    save(sprintf('observations_%s.mat', date), 'observations');
end
end
