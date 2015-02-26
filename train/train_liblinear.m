function [model, info] = train_liblinear(Xtrain, Ytrain, s, c, verbose)
% [model, info] = train_liblinear(Xtrain, Ytrain, s, c)
% Trains a SVM using liblinear.
% type : set type of solver (default 1)
%   for multi-class classification
% 	 1 -- L2-regularized L2-loss support vector classification (dual)
% 	 3 -- L2-regularized L1-loss support vector classification (dual)
% 	 5 -- L1-regularized L2-loss support vector classification
%    6 -- L1-regularized logistic regression
% 	 7 -- L2-regularized logistic regression (dual)
% 	12 -- L2-regularized L2-loss support vector regression (dual)
% 	13 -- L2-regularized L1-loss support vector regression (dual)
%
% Xtrain - train data
% Ytrain - train label
% s      - type for -s option
% c      - cost parameter

% Handle default option
if nargin < 3, s = 1; end
if nargin < 4, c = 0.1; end
if nargin < 5, verbose = false; end

% Display type
type_list = [0 1 2 3 4 5 6 7 12 13];
type_ind = (type_list == s);
if ~nnz(type_list), error('Wrong model type: %d.', s); end

% Train model
tic
if verbose
	fprintf('*** Start training %s with C = %g.. \n', type_name{type_ind}, c)
end

option = sprintf('-s %d -q -c %g', s, c)

model = liblinear_train(Ytrain, Xtrain, option)
