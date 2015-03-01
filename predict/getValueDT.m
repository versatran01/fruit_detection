function [p] = getValueDT(node, X)
%GETVALUEDT Recursively retrieve the value of observations from a binary
% decision tree. The output values are not rounded and fall in [0,1].
%
% Note: This method expects X to be transposed (features in rows) for
% performance reasons.
N = size(X,2);
if node.terminal
    p = ones(1,N) * node.value;
    return;
end
% find all left and right observations
l_idx = X(node.fidx, :) <= node.fval;
r_idx = ~l_idx;
% descend down the tree
p = zeros(1,N);
p(l_idx) = getValueDT(node.left, X(:,l_idx));
p(r_idx) = getValueDT(node.right, X(:,r_idx));
end
