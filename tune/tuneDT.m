function [ result ] = tuneDT( Xtrain, Ytrain, featidx, ...
    nlevels, nfolds, errorIndex, rounded )
%TUNEDT Tune binary classification decision tree.
% `featidx` are the indices of features to use.
% `nlevels` is the number of different depths to try.
% `errorIndex` is the type of error metric to optimize (see crossValidate).
% `rounded` indicates whether outputs of the model should be rounded. This
% only applies to the final model - not the cross-validated intermediates.
errors = [];
numSplits = 20;
if isempty(featidx)
    featidx = true(1, size(Xtrain,2));
end
D = size(Xtrain,2);
Xtrain = Xtrain(:,featidx);
for l=1:nlevels
   train_cb = @(x,y)trainDT(x,y, 'maxDepth', l, 'numSplits', numSplits);
   predict_cb = @predictDT;
   errs = crossValidate(Xtrain, Ytrain, nfolds, train_cb, predict_cb);
   errors(l,:) = errs;
   fprintf('- Finished evaluating depth = %i\n', l);
end
if errorIndex==1    % rms, use min
    [~, best_idx] = min(errors(:,errorIndex),[],1);
else
    [~, best_idx] = max(errors(:,errorIndex),[],1);
end
% output all errors
for l=1:nlevels
    errs = errors(l,:);
    if l==best_idx
        char = '*'; % denote the selected param
    else
        char = '-';
    end
    fprintf('%s Metrics for depth = %i are %.4f/%.4f/%.4f/%.4f\n',...
       char, l, errs(1), errs(2), errs(3), errs(4));
end
errors = errors(best_idx,:);
% retrain final model
result.param = trainDT(Xtrain, Ytrain, 'maxDepth', best_idx,...
    'numSplits', numSplits, 'rounded', rounded);
result.dimension = D;
result.featIndex = featidx;
result.datetime = datetime;
result.maxDepth = best_idx;
result.errors = errors;
result.predict = @predictDT;
end
