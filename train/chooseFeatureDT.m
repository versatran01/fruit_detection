function [fidx, val, max_ig] = chooseFeatureDT(X, Y, Xrange, colidx, numSplits)
% CHOOSEFEATUREDT - Selects feature with maximum information gain.
%
% Given N x D data X and N x 1 labels Y, where X(:,j) can take on values in 
% between Xrange(1) and Xrange(2), select the split X(:,FIDX) <= VAL 
% to maximize information gain MAX_IG.

% compute conditional entropy for each feature.
ig = [];
split_vals = [];

for i = colidx    
    % generate some possible splits
    Xmin = Xrange(1,i);
    Xmax = Xrange(2,i);

    r = linspace(Xmin, Xmax, numSplits);
    split_f = bsxfun(@le, X(:,i), r(1:end-1));

    % compute information gain
    idx = 1:size(split_f,2);
    IG = fastig(split_f,Y,idx,[0 1]);
    
    % Choose split with best IG, and record the value split on.
    [ig(i), best_split] = max(IG);
    split_vals(i) = r(best_split);
end
% Choose feature with best split.
[max_ig, fidx] = max(ig);
val = split_vals(fidx);
end
