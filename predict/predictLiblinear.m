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

N = size(X, 1);
if param.Parameters == 7 || param.Parameters == 0 || param.Parameters == 6
    Yhat = liblinearpredict(ones(N, 1), sparsify(X), param, '-b 1 -q');
elseif param.Parameters == 4 && param.nr_class == 2
    % SVC by cramer and singer w/ only 2 labels, used MATLAB to make
    % prediction
    % ~30x faster than calling liblinearpredict
    w = param.w(2,:);   % [1xK] vector
    b = param.bias;     % scalar (NOTE: using this gives wrong result)
    
    pred = w * X';      % todo: why does bias generate incorrect result...
    idx = pred > 0;
    
    Yhat = zeros(N,1);
    Yhat(idx) = param.Label(2);
    Yhat(~idx) = param.Label(1);
else
    Yhat = liblinearpredict(ones(N, 1), sparsify(X), param, '-q');
end

% Clamp predicted labels
if clamp
	Yhat(Yhat > 1) = 1;
	Yhat(Yhat < 0) = 0;
end
end

function X = sparsify(X)
    % Handle data sparsity
    if ~issparse(X)
        X = sparse(X);
    end
end
