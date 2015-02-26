%% init_observations.m
init;

NUM_SAMPLES = 50000;    % number of observations to sample
FRACTION_TRAIN = 0.8;   % fraction of data to use for training

% load observations
obvs_path = '';
if ~isempty(OBSERVATION_PATH)
   observations_path = sprintf('%s/%s',OBSERVATION_PATH,...
       'observations_24-Feb-2015.mat');
else
    % todo: don't hardcode this
    obvs_path = 'observations_24-Feb-2015.mat';
end
load(obvs_path);

npos = size(observations.Xpos,1);
nneg = size(observations.Xneg,1);

if NUM_SAMPLES > npos+nneg
    error('NUM_SAMPLES is too large');
elseif FRACTION_TRAIN<=0 || FRACTION_TRAIN>=1
    error('FRACTION_TRAIN should be in (0,1)');
end

% create X matrix and sample the set to work with
X = [observations.Xpos; observations.Xneg];
Y = [ones(npos,1); zeros(nneg,1)];
idx = randperm(npos+nneg);
idx = idx(1:NUM_SAMPLES);
X = X(idx,:);
Y = Y(idx,:);

% now create the training and testing sets
ntrain = floor(FRACTION_TRAIN * NUM_SAMPLES);
idx = randperm(NUM_SAMPLES);
idxtrain = idx(1:ntrain);
idxtest = idx((ntrain+1):end);

Xtrain = X(idxtrain,:);
Ytrain = Y(idxtrain,:);
Xtest = X(idxtest,:);
Ytest = Y(idxtest,:);

