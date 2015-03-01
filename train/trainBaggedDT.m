function [model] = trainBaggedDT(X, Y, varargin)
%TRAINBAGGEDDT Train a bagged binary decision tree classifier.
% See trainDT for base parameters.
%
% Parameters:
%   `T` is the number of bags to train.
%   `frac` is the fraction of training data per bag.
%   `mode` is the combination scheme, either 'vote' or 'average'
defaults.T = 20;
defaults.frac = 0.6;
defaults.maxDepth = 5;
defaults.numSplits = 10;
defaults.mode = 'vote';
defaults.verbose = true;
options = propval(varargin, defaults);

% check input arguments
if options.T <= 0
    error('T must be a positive integer');
end
if options.frac <= 0 || options.frac >= 1
    error('frac must be in the range (0,1)');
end
valid_modes = {'vote', 'average'};
if ~any(strcmp(options.mode, valid_modes))
    error('Invalid mode selected!');
end
model.options = options;
model.trees = {};
M = size(X, 1); % total sizeof training data
for t=1:options.T
    % randomly sample the data
    ind = randperm(M);
    subset_size = floor(M * options.frac);
    ind_clip = ind(1:subset_size);
    
    y = Y(ind_clip);
    x = X(ind_clip,:);
    model.trees{t} = trainDT(x, y, 'maxDepth', options.maxDepth,...
        'numSplits', options.numSplits);
    if options.verbose
        fprintf('Finished bag [%i/%i].\n',t,options.T);
    end
end
end
