function [ points ] = createCirclePoints( center, radius, N )
%CREATECIRCLEPOINTS Generate circle points.
if nargin < 3
    N = 100;
end
if N < 3
    error('N must be >= 3');
end
if numel(center) ~= 2
    error('center must be a 2-element vector');
end
angles = linspace(0,N-1,N)' / (N-1) * 2 * pi;
points = [cos(angles) sin(angles)] * radius;
points = bsxfun(@plus,points,center);
end
