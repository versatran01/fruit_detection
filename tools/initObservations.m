function sampled_observations = initObservations(observations_dir, ...
												 observations_name, ...
	                                             num_samples, fraction_train)
% INITOBSERVATIONS Initialize observations by subsampling from the whole
% observations

% load observations
observations = loadObservations(observations_dir, observations_name);

npos = size(observations.Xpos, 1);
nneg = size(observations.Xneg, 1);
if isempty(num_samples)
    num_samples = npos+nneg;
end

if num_samples > (npos + nneg)
	error(sprintf('num_samples [%g] is bigger then num_observations [%g]', ...
		           num_samples, npos + nneg));
elseif num_samples <= 0
	error(sprintf('num_samples [%g] should be positive', num_samples));
elseif fraction_train <= 0 || fraction_train >= 1
	error(sprintf('fraction_train [%0.2f] should be in (0, 1)', ...
		          fraction_train));
end

% create X matrix and sample the set to work with
X = [observations.Xpos; observations.Xneg];
Y = [ones(npos, 1);, zeros(nneg, 1)];
idx = randperm(npos + nneg);
idx = idx(1:num_samples);
X = X(idx, :);
Y = Y(idx, :);

ntrain = floor(fraction_train * num_samples);
idx = randperm(num_samples);
idx_train = idx(1:ntrain);
idx_test = idx((ntrain + 1):end);

sampled_observations.Xtrain = X(idx_train, :);
sampled_observations.Ytrain = Y(idx_train);
sampled_observations.Xtest = X(idx_test, :);
sampled_observations.Ytest = Y(idx_test, :);

fprintf('Sampled %g entries from observations, train fraction %0.2f.\n', ...
	    num_samples, fraction_train);

end


function observations = loadObservations(observations_dir, observations_name)
% LOADOBSERVATIONS Load observations from hard disk
%
% INPUT:
%  observations_dir  - directory
%  observations_name - mat file name

if ~isempty(observations_dir)
    if ~exist(observations_dir, 'dir')
        error(sprintf('%s does not exist', observations_dir))
    end
    observations_path = [observations_dir, '/', observations_name];
else
    observations_path = observations_name;
end

% Load observation
obs = load(observations_path);
observations = obs.observations;

fprintf('Load %s.\n', observations_path);

end

