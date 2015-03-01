function [ Y ] = predictDT( model, X )
%PREDICT Predict using a binary-tree based classifier.
X = X';
Y = round(getValueDT(model.root, X)');
end
