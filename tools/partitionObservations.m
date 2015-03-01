function [ sampled ] = partitionObservations( obs, fraction_train,...
    nsamples )
%PARTITIONOBSERVATIONS Partition observations into training & testing.
npos = size(obs.Xpos,1);
nneg = size(obs.Xneg,1);
if nargin < 3
    nsamples = npos+nneg;
end

if nsamples > (npos + nneg)
	error('nsamples [%g] is bigger then num_observations [%g]', ...
		           nsamples, npos + nneg);
elseif nsamples <= 0
	error('num_samples [%g] should be positive', num_samples);
elseif fraction_train <= 0 || fraction_train >= 1
	error('fraction_train [%0.2f] should be in (0, 1)', fraction_train);
end

% create X matrix and sample the set to work with
X = [obs.Xpos; obs.Xneg];
Y = [ones(npos, 1); zeros(nneg, 1)];
idx = randperm(npos + nneg);
idx = idx(1:nsamples);
X = X(idx, :);
Y = Y(idx, :);

ntrain = floor(fraction_train * nsamples);
idx = randperm(nsamples);
idx_train = idx(1:ntrain);
idx_test = idx((ntrain + 1):end);

sampled.Xtrain = X(idx_train, :);
sampled.Ytrain = Y(idx_train);
sampled.Xtest = X(idx_test, :);
sampled.Ytest = Y(idx_test, :);
end
