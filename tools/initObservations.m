function sampled_observations = initObservations(observations_dir, ...
												 observations_name, ...
	                                             num_samples, fraction_train)
% INITOBSERVATIONS Initialize observations by subsampling from the whole
% observations

% load observations
observations = loadObservations(observations_dir, observations_name);

sampled_observations = partitionObservations(observations,...
    fraction_train, num_samples);

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
