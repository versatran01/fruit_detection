function Yhat = predictLiblinear(param, X, clamp)
% PREDICTLIBLINEAR Generate predictions using a liblinear model
%  Predict Yhat for Xtest using liblinearpredict with any liblinear model
%
% INPUT:
%  model - liblinear param
%  Xtest - testing instance matrix
%  clamp - clamp predicted label between [0,1]
%
% OUTPUT:
%  Yhat  - predicted label

if nargin < 3, clamp = true; end

% Handle data sparsity
if ~issparse(X)
	X = sparse(X);
end

N = size(X, 1);
if param.Parameters == 7 || param.Parameters == 0 || param.Parameters == 6
    Yhat = liblinearpredict(ones(N, 1), X, param, '-b 1 -q');
else
    Yhat = liblinearpredict(ones(N, 1), X, param, '-q');
end

% Clamp predicted labels
if clamp
	Yhat(Yhat > 1) = 1;
	Yhat(Yhat < 0) = 0;
end

end
