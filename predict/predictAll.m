function [ Y ] = predictAll( model, X )
%PREDICTALL Classify pixels using a tuned model.
% `model` is the result of a tuning method (libSVM, libLinear, etc)
% `X` is NxD input pixels. N pixels, in D-dimensional feature space.
N = size(X,1);
D = size(X,2);
is_ensemble = false;    % todo: add support for ensemble model
if is_ensemble
    % run on all models and combine results
    
else
    if model.dimension ~= D
        error('Model was trained on a different dimension feature space');
    end
    Y = model.predict(model.model, X);
end
end
