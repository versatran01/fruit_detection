function [ Y ] = predictDT( model, X )
%PREDICT Predict using a binary-tree based classifier.
X = X';
Y = getValueDT(model.root, X)';
if model.options.rounded
    Y = round(Y);
end
end
