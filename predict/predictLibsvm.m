function Yhat = predictLibsvm( model, Xtest )
N = size(Xtest, 1);
% first parameter is junk to be ignored
Yhat = svmpredict(ones(N, 1), Xtest, model, '-b 1');
end
