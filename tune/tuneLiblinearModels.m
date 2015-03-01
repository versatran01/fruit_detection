function tuneLiblinearModels(observations, tune_model_types, feat_ind)

nlevel = 2;
nfolds = 5;
models_dir = 'models';

[model_types, model_names, model_acronyms] = getLiblinearTypes();
if nargin < 2, tune_model_types = 0:7; end
if nargin < 3, feat_ind = [1:6, 11, 12]; end

for i = 1:length(tune_model_types)
    model_type = tune_model_types(i);
    model_ind = find(model_types == model_type);
    model_name = model_names{model_ind};
    fprintf('Tunning %s.\n', model_name);
    model_acronym = model_acronyms{model_ind};
    % Tune each individual model
    result = tuneLiblinear(observations.Xtrain(:, feat_ind), ...
                           observations.Ytrain, ...
                           nlevel, nfolds, model_type);
    result.name = model_name;
    result.acronym = model_acronym;
    result.feat_ind = feat_ind;
    % Save model to disk
    model_path = [models_dir, '/', model_acronym];
    save(model_path, 'result');
    fprintf('Model saved to %s.\n', model_path);
end

end

