function [ smallest ] = smallestDistance( dist )
%SMALLESTDISTANCE Find the smallest value per column, above the diagonal.
% For use with pdist2.
% Note: We assume dist is symmetric.
M = size(dist,1);
N = size(dist,2);
% make the (sub-) diagonal nan
dist = triu(dist,1) + tril(NaN(M,N));
[~,small] = min(dist, [], 1); % column-wise min for smallest (ignoring nan)
% convert to logical 2D indices
ind = sub2ind(size(dist),small,1:numel(small));
smallest = false(size(dist));
smallest(ind) = true;
smallest(1,1) = false;  % min() selects the first in the first column, remove it
end
