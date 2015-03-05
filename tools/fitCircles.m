function [ X ] = fitCircles( points, niters, inlierthresh,...
    inlierfrac, earlyexit )
%FITCIRCLES 
%   `points` is an Nx2 vector of points
%   `niters` is the max number of iterations
%   `inliersdist` is the threshold for determining an inlier of a circle.
%   `inlierfrac` is the fraction of points required to form an new circle.
%   `earlyexit` is the number of circles that triggers early exit.
N = size(points,1);
X = [];
for i=1:niters
    % randomly sample
    idx = randsample(N,3);
    pts = points(idx,:);
    A = [2*pts ones(3,1)];
    if abs( det(A) ) >= 1
        % det should be an integer
        b = sum(pts.*pts, 2);
        x = A\b;
        % convert x(3) to radius squared
        x(3) = x(3) + x(1)*x(1) + x(2)*x(2);
    else
        continue;
    end
    
    % this formula: (x - cx)^2 + (y - cy)^2 - r^2 ~= 0
    dist = sum(bsxfun(@minus,points,x(1:2)') .^2, 2) - x(3);
    dist = dist.^2;
    inliers = dist < (inlierthresh*inlierthresh);
    
    % check if this is a possible solution
    if nnz(inliers) > inlierfrac * N
        % fit it again
        pts = points(inliers,:);
        A = [2*pts ones(size(pts,1),1)];
        b = sum(pts.*pts, 2);
        x = A\b;
        % convert x(3) to radius squared
        x(3) = x(3) + x(1)*x(1) + x(2)*x(2);
        
        % this is a possible solution
        X(:,end+1) = [x; nnz(inliers)];
    end
    if size(X,2) >= earlyexit
        break;
    end
end
% convert to radius and arrange best to worst
if ~isempty(X)
    X(3,:) = sqrt(X(3,:));
    X = X';
    X = sortrows(X,[4 3]);
    X = flipud(X);
end
end
