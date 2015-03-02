function [ Y ] = predictAll( model, X )
%PREDICTALL Classify pixels using a tuned model.
% `model` is the result of a tuning method (libSVM, libLinear, etc)
% `X` is NxD input pixels. N pixels, in D-dimensional feature space.
D = size(X,2);
if isfield(model, 'sub_models')
    % this is an ensemble
    Y = predictEnsemble(model, X);
else
    if model.dimension ~= D
        error('Model was trained on a different dimension feature space');
    end
    if isfield(model, 'featIndex')
        % apply feature indices to feature space
        X = X(:, model.featIndex);
    end
    Y = model.predict(model.model, X);
end
end
