function ensemble = tuneEnsemble(observations, sub_model_names)

% model_names - cell array of strings of model names that can be found in
%               folder models. If not specified or empty, tuneEnsemble will
%               try to use all the models that can be found

if nargin < 2, sub_model_names = {}; end
sub_models = loadModels(sub_model_names);

Xtrain = observations.Xtrain;
Xvalid = observations.Xtest;

Ytrain = observations.Ytrain;
Yvalid = observations.Ytest;

Ytrain_hat = [];
Yvalid_hat = [];

valid_rmse = [];

for i = 1:length(sub_models)
    sub_model = sub_models{i};
    Ytrain_n = sub_model.predict(sub_model.param, Xtrain(:, sub_model.feat_ind));
    Yvalid_n = sub_model.predict(sub_model.param, Xvalid(:, sub_model.feat_ind));
    sum(Ytrain_n)
    Ytrain_hat = [Ytrain_hat Ytrain_n];
    Yvalid_hat = [Yvalid_hat Yvalid_n];
    valid_rmse(i) = rootMeanSquare(Yvalid_n - Yvalid);
    fprintf('Validation RMSE for %s -> %f.\n', sub_model.name, valid_rmse(end));
end

ensemble_rmse = rootMeanSquare(Yvalid - mean(Yvalid_hat, 2));
weights = 1./valid_rmse;
weights = weights / sum(weights);
weighted_rmse = rootMeanSquare(Yvalid - sum(bsxfun(@times, Yvalid_hat, weights), 2));
regression_weights = inv(Ytrain_hat' * Ytrain_hat + 1000 * eye(size(Ytrain_hat, 2))) ...
                     * Ytrain_hat' * Ytrain;
regression_rmse = rootMeanSquare(Yvalid - Yvalid_hat * regression_weights);

fprintf('\n=========================================');
fprintf('\n ** Average Ensemble RMSE: %.4f **\n', ensemble_rmse)
fprintf('=========================================');
fprintf('\n ** Weighted Ensemble RMSE: %.4f **\n', weighted_rmse)
fprintf('=========================================');
fprintf('\n ** Regression Ensemble RMSE: %.4f **\n', regression_rmse)
fprintf('=========================================\n');

ensemble.weights = regression_weights;
ensemble.sub_models = sub_models;
ensemble.predict = @predictEnsemble;

end

function models = loadModels(model_names, models_dir)
if nargin < 2, models_dir = 'models'; end

listings = dir(models_dir);

models = {};
k = 1;
for i = 1:numel(listings)
    listing = listings(i);
    if ~listing.isdir
        if ~isempty(strfind(listing.name, '.mat'))
            model = load([models_dir, '/', listing.name]);
            models{k} = model.model;
            k = k + 1;
        end
    end
end

end