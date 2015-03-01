function [ Y ] = predictDT( model, X, rounded )
%PREDICT Predict using a binary-tree based classifier.
if nargin < 3
    rounded = true;
end
X = X';
Y = getValueDT(model.root, X)';
if rounded
    Y = round(Y);
end
end
