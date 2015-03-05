function [ inside ] = pointsInCircles( circles, points )
%POINTSINCIRCLES Check if an Nx2 vector of `points` are inside an Mx3 vector
% of `circles`. Circles are in form [x,y,radius].
M = size(circles,1);
N = size(points,1);
if size(circles,2) ~= 3 || size(points,2) ~= 2
    error('Check the dimensions of your inputs');
end
inside = false(M,N);
for i=1:M
    center = circles(i,1:2);
    radius = circles(i,3);
    
    dist = bsxfun(@minus,center,points);
    dist = sqrt( sum(dist.^2, 2) );
    
    in = dist < radius;
    inside(i,:) = in;
end
end

