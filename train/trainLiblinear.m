function param = trainLiblinear(Xtrain, Ytrain, s, c, verbose)
% TRAINLIBLINEAR Trains a SVM using liblinear.
%  type : set type of solver (default 1)
%  for multi-class classification
%	   0 -- L2-regularized logistic regression (primal)
%	   1 -- L2-regularized L2-loss support vector classification (dual)
%	   2 -- L2-regularized L2-loss support vector classification (primal)
%	   3 -- L2-regularized L1-loss support vector classification (dual)
%	   4 -- support vector classification by Crammer and Singer
%	   5 -- L1-regularized L2-loss support vector classification
%	   6 -- L1-regularized logistic regression
%	   7 -- L2-regularized logistic regression (dual)
%  for regression
%	  11 -- L2-regularized L2-loss support vector regression (primal)
%	  12 -- L2-regularized L2-loss support vector regression (dual)
%	  13 -- L2-regularized L1-loss support vector regression (dual)
%
% INPUT:
%  Xtrain - train data
%  Ytrain - train label
%  s      - type for -s option
%  c      - cost parameter
%
% OUTPUT:
%  param  - liblinear model

[type_id_list, type_name_list] = getLiblinearTypes();

% Handle default option
if nargin < 3, s = 1; end
if nargin < 4, c = 0.1; end
if nargin < 5, verbose = false; end

% Display type
type_ind = (type_id_list == s);
if ~nnz(type_ind), error('Wrong liblinear type: %d.', s); end
type_name = type_name_list{type_ind};

% Handle data sparsity
if ~issparse(Xtrain)
	Xtrain = sparse(Xtrain);
end

% Train model
if verbose
	fprintf('+++ Start training %s with C = %g.\n', type_name, c);
	tic
end

option = sprintf('-s %d -c %g -q', s, c);
param = liblineartrain(Ytrain, Xtrain, option);

if verbose
	time = toc;
	fprintf('--- Finish training %s with time: %f.\n', type_name, time);
end

end
