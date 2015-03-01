function [model] = trainDT(X, Y, varargin)
%TRAINDT - Train a binary tree decision classifier. Information gain is
% used at every level of the tree in order to determine the best feature to
% use for classification.
%
% Parameters:
%   `X` is an NxD matrix of observations.
%   `Y` is an Nx1 matrix of (only) binary labels (0/1).
%   `maxDepth` is the max depth of the tree.
%   `numSplits` is number of levels of possible splits to consider at each
%   level.
%   `verbose` turns on and off verbose output.
defaults.maxDepth = 3;
defaults.numSplits = 10;
defaults.verbose = false;
options = propval(varargin, defaults);

% determine range of values in X
Xmin = min(X,[],1);
Xmax = max(X,[],1);
Xrange = [Xmin; Xmax];
% train model
model.root = splitNode(X, Y, Xrange, mean(Y), 1:size(X,2), 1, options);
model.options = options;
model.dimension = size(X,2);
end

function [node] = splitNode(X, Y, Xrange, value,...
    colidx, depth, options)

% Return terminal node if:
%  - we are at the maximum depth
%  - we have Y equal to all 0's or all 1's 
%  - we have only a single (or no) examples left
%  - we have no features left to split on
if depth == options.maxDepth || all(Y==0) || all(Y==1) || ...
        numel(Y) <= 1 || numel(colidx) == 0
    node.terminal = true;
    node.fidx = [];
    node.fval = [];
    if numel(Y) == 0
        node.value = value;
    else
        node.value = mean(Y);
    end
    node.left = []; node.right = [];

    if options.verbose
        fprintf('Depth %d [%d/%d]: Leaf node: = %s\n',...
            depth, sum(Y==0), sum(Y==1), mat2str(node.value));
    end
    return;
end
node.terminal = false;

% choose a feature to split on using information gain.
[node.fidx, node.fval, max_ig] = ...
    chooseFeatureDT(X, Y, Xrange, colidx, options.numSplits);
% remove this feature from future consideration
colidx(colidx == node.fidx) = [];

% split the data based on this feature
leftidx = X(:,node.fidx) <= node.fval;
rightidx = ~leftidx;

% mean of all labels remaining at this depth
node.value = mean(Y);

if options.verbose
    fprintf('Depth %d [%d]: split on feature %d <= %.2f (L/R = %d/%d)\n', ...
        depth, numel(Y), node.fidx, node.fval, nnz(leftidx), nnz(rightidx));
end

% recursively generate left and right branches.
node.left = splitNode( X(leftidx, :), Y(leftidx), Xrange,...
    node.value, colidx, depth+1, options);

node.right = splitNode( X(rightidx, :), Y(rightidx), Xrange,...
    node.value, colidx, depth+1, options);
end
