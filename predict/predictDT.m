function [ Y ] = predictDT( model, X )
%PREDICT Predict using a binary-tree based classifier.
if model.dimension ~= size(X,2)
    error('This model was trained on a different size feature space');
end
X = X';
Y = round(getValueDT(model.root, X)');
end
