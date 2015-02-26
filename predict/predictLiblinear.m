function Yhat = predictLiblinear(model, Xtest, clamp)
% PREDICTLIBLINEAR Generate predictions using a liblinear model
%  Predict Yhat for Xtest using liblinearpredict with any liblinear model
%
% INPUT:
%  model - liblinear model
%  Xtest - testing instance matrix
%  clamp - clamp predicted label between [0,1]
%
% OUTPUT:
%  Yhat  - predicted label

if nargin < 3, clamp = true; end

N = size(Xtest, 1);
Yhat = liblinearpredict(ones(N, 1), Xtest, model, '-q');

% Clamp predicted labels
if clamp
	Yhat(Yhat > 1) = 1;
	Yhat(Yhat < 0) = 0;
end

end
