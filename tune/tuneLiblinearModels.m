function tuneLiblinearModels(observations, tune_param_types, feat_ind)
% TUNELIBLINEARMODELS Tune all liblinear models and save them to disk.
%  Note: `observations` should be the result of `partitionObservations` method.

nlevel = 2;
nfolds = 4;
models_dir = 'models';

[liblinear_types, liblinear_names, liblinear_acronyms] = getLiblinearTypes();
if nargin < 2, tune_param_types = 0:7; end
if nargin < 3, feat_ind = 1:9; end

for i = 1:length(tune_param_types)
    param_type = tune_param_types(i);
    param_ind = find(liblinear_types == param_type);
    model_name = liblinear_names{param_ind};
    fprintf('Tuning %s.\n', model_name);
    model_acronym = liblinear_acronyms{param_ind};
    % Tune each individual model
    model = tuneLiblinear(observations.Xtrain(:, feat_ind), ...
                           observations.Ytrain, ...
                           nlevel, nfolds, param_type);
    model.name = model_name;
    model.acronym = model_acronym;
    model.featIndex = feat_ind;
    % Save model to disk
    model_path = [models_dir, '/', model_acronym];
    save(model_path, 'model');
    fprintf('Model saved to %s.\n', model_path);
end

end

