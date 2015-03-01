function tuneLiblinearModels(observations, tune_model_types)

nlevel = 2;
nfolds = 5;
models_dir = 'models';

[model_types, model_names, model_short_names] = getLiblinearTypes();
if nargin < 2, tune_model_types = [0, 1, 2, 5, 7]; end

for i = 1:length(tune_model_types)
    model_type = tune_model_types(i);
    model_ind = find(model_types == model_type);
    model_name = model_names{model_ind};
    fprintf('Tunning %s.\n', model_name);
    model_short_name = model_short_names{model_ind};
    % Tune each individual model
    result = tuneLiblinear(observations.Xtrain, observations.Ytrain, ...
                           nlevel, nfolds, model_type);
    % Save model to disk
    model_path = [models_dir, '/', model_short_name];
    save(model_path, 'result');
    fprintf('Model saved to %s.\n', model_path);
end

end

