function [ inside ] = pointsInBoxes( boxes, points )
%POINTSINBOXES Check if an Nx2 vector of `points` are inside an Mx4 vector
% of `boxes`. Boxes are in form [x,y,w,h].
M = size(boxes,1);
N = size(points,1);
if size(boxes,2) ~= 4 || size(points,2) ~= 2
    error('Check the dimensions of your inputs');
end
inside = false(M,N);
for i=1:M
    tl = boxes(i,1:2);
    br = tl + boxes(i,3:4);
    
    in = bsxfun(@ge, points, tl) & bsxfun(@le, points, br);
    in = in(:,1) & in(:,2); % combine both x & y
    inside(i,:) = in';
end
end
