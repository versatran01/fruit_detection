function observations = generateObservations(do_save)
% GENERATEOBSERVATIONS Generate observations by prompting user to select
% dataset directory and descriptor file

if nargin < 1, do_save = false; end

% Load dataset
dataset_path = uigetdir('', 'Select dataset directory');
if ~dataset_path
    error('No dataset selected');
end
dataset = Dataset(dataset_path);

% Load descriptors
[descriptors_file, descriptors_path] = uigetfile('*.mat', ...
                                                 'Select descriptor file');
if ~descriptors_file
    error('No descriptors selected');
end

descriptors = load([descriptors_path, descriptors_file]);
descriptors = descriptors.descriptors;

scale = 0.5;
maxRatio = 5;
observations = generate_observations(dataset, descriptors, scale, maxRatio);

% Save descriptors
if do_save
    save(sprintf('observations_%s.mat', date), 'observations');
end

end

function observations = generate_observations(dataset, descriptors, ...
                                              image_scale, maxRatio)
%GENERATE_OBSERVATIONS 

n_data = dataset.size();

% Scale all images
for i = 1:n_data
    dataset.images{i} = imresize(dataset.images{i}, image_scale);
end

% Generate feature space
Xpos = {};
Xneg = {};
parfor i = 1:n_data
    fprintf('Processing image %i\n...', i);
    desc = applyDescriptors(dataset.images{i}, descriptors{1});
    % sample the examples
    [Xp, Xn] = sampleExamples(desc, dataset.selections{i}, ...
                              dataset.masks{i}, image_scale);
              
    npos = size(Xp,1);
    nneg = size(Xn,1);
    maxPos = maxRatio*npos;
    if nneg > maxPos
        idx = randperm(nneg);
        idx = idx(1:maxPos);
        Xn = Xn(idx,:); % throw away some negative to bring down the ratio
    end
    Xpos{i} = Xp;
    Xneg{i} = Xn;
end

Xpos = cell2mat(Xpos');
Xneg = cell2mat(Xneg');

observations.Xpos = Xpos;
observations.Xneg = Xneg;
observations.datetime = datetime;

end

