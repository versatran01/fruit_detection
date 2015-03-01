function ensemble_model = tuneEnsemble(model_names)

% model_names - cell array of strings of model names that can be found in
%               folder models. If not specified or empty, tuneEnsemble will
%               try to use all the models that can be found

if nargin < 1, model_names = {}; end
loadModels(model_names);




end

function models = loadModels(model_names, models_dir)
if nargin < 2, models_dir = 'models'; end

listing = dir(models_dir)

end