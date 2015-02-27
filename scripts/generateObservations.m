%% generateObservations.m
init;
RATIO = 1;  % ratio of negative to positive training examples
DESCRIPTORS_PATH = 'descriptors/kmeans.mat';
IMAGE_SCALE = 0.5;

%% load dataset
N = dataset.size();

% scale all images down...
for i=1:N
    dataset.images{i} = imresize(dataset.images{i}, IMAGE_SCALE);
end

%% generate feature space
Xpos = {};
Xneg = {};
parfor i=1:N
    fprintf('Processing image %i\n...', i);
    % process the image
    % todo: assume one model for now, add support for multi-scale later
    desc = applyDescriptors(dataset.images{i}, descriptors{1});
    % sample the examples
    [Xp,Xn] = sampleExamples(desc,...
        dataset.selections{i}, dataset.masks{i}, RATIO, IMAGE_SCALE);
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
