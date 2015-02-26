function model = trainLiblinear(Xtrain, Ytrain, s, c, verbose)
% model = trainLiblinear(Xtrain, Ytrain, s, c)
% Trains a SVM using liblinear.
% type : set type of solver (default 1)
% for multi-class classification
%	  0 -- L2-regularized logistic regression (primal)
%	  1 -- L2-regularized L2-loss support vector classification (dual)
%	  2 -- L2-regularized L2-loss support vector classification (primal)
%	  3 -- L2-regularized L1-loss support vector classification (dual)
%	  4 -- support vector classification by Crammer and Singer
%	  5 -- L1-regularized L2-loss support vector classification
%	  6 -- L1-regularized logistic regression
%	  7 -- L2-regularized logistic regression (dual)
% for regression
%	 11 -- L2-regularized L2-loss support vector regression (primal)
%	 12 -- L2-regularized L2-loss support vector regression (dual)
%	 13 -- L2-regularized L1-loss support vector regression (dual)
%
% Xtrain - train data
% Ytrain - train label
% s      - type for -s option
% c      - cost parameter

type_id_list = [0:7, 11:13];
type_name_list = {...
    'L2-regularized logistic regression (primal)', ...
    'L2-regularized L2-loss support vector classification (dual)', ...
    'L2-regularized L2-loss support vector classification (primal)', ...
    'L2-regularized L1-loss support vector classification (dual)', ...
    'support vector classification by Crammer and Singer', ...
    'L1-regularized L2-loss support vector classification', ...
    'L1-regularized logistic regression', ...
    'L2-regularized logistic regression (dual)', ...
    'L2-regularized L2-loss support vector regression (primal)', ...
    'L2-regularized L2-loss support vector regression (dual)', ...
    'L2-regularized L1-loss support vector regression (dual)'};


% Handle default option
if nargin < 3, s = 1; end
if nargin < 4, c = 0.1; end
if nargin < 5, verbose = false; end

% Display type
type_ind = (type_id_list == s);
type_name = type_name_list{type_ind};
if ~nnz(type_list), error('Wrong model type: %d.', s); end

% Train model
tic
if verbose
	fprintf('+++ Start training %s with C = %g.\n', type_name, c)
end

option = sprintf('-s %d -q -c %g', s, c)

model = liblinear_train(Ytrain, Xtrain, option)
time = toc

if verbose
	fprintf('--- Finish training %s with time: %f.\n', type_name, time)
end

end
