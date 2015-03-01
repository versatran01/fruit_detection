function [ Ypred ] = predictBaggedDT( model, Xtest )
%PREDICTBAGGEDDT Predict using bagged binary decision trees.
% Usage is the same as predictDT.
M = size(Xtest, 1); % num observations
predictions = zeros(M, model.options.T);
for t=1:model.options.T
    predictions(:,t) = predictDT(model.trees{t}, Xtest);
end

if strcmp(model.options.mode, 'vote')
    Ypred = mode(round(predictions), 2);
else
    % mode = average
    Ypred = round(mean(predictions, 2));
end
end
