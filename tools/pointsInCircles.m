function [ inside ] = pointsInCircles( circles, points )
%POINTSINCIRCLES Check if an Nx2 vector of `points` are inside an Mx3 vector
% of `circles`. Circles are in form [x,y,radius].
M = size(circles,1);
N = size(points,1);
if size(circles,2) ~= 3 || size(points,2) ~= 2
    error('Check the dimensions of your inputs');
end
dist = pdist2(circles(:,1:2), points);
inside = bsxfun(@le, dist, circles(:,3));
end
