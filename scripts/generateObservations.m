%% generateObservations.m
init;
RATIO = 1;  % ratio of negative to positive training examples
DESCRIPTORS_PATH = 'descriptors/kmeans.mat';

%% load dataset
dataset = Dataset(DATASET_PATH);
N = dataset.size();

%% load descriptors
load(DESCRIPTORS_PATH);

%% generate feature space
Xpos = {};
Xneg = {};
parfor i=1:N
    fprintf('Processing image %i\n...', i);
    % process the image
    % todo: assume one model for now, add support for multi-scale later
    desc = applyDescriptors(dataset.images{i}, models{1});
    % sample the examples
    [Xp,Xn] = sampleExamples(desc,...
        dataset.selections{i}, dataset.masks{i}, RATIO);
    Xpos{i} = Xp;
    Xneg{i} = Xn;
end

Xpos = cell2mat(Xpos');
Xneg = cell2mat(Xneg');

%% save
observations.Xpos = Xpos;
observations.Xneg = Xneg;
observations.descriptors_path = DESCRIPTORS_PATH;
observations.datetime = datetime;
save(sprintf('observations_%s.mat', date), 'observations');
