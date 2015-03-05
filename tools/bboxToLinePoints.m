function [ points ] = bboxToLinePoints( bbox )
%BBOXTOLINEPOINTS Convert Nx4 vector of lines points to a 5x2xN vector of
% line coordinates (for plotting).
if isempty(bbox)
    points = [];
    return;
end
N = size(bbox,1);
if size(bbox,2) ~= 4
    error('bbox must be Nx4');
end

points = zeros(5,2,N);
for i=1:N
    box = bbox(i,:);
    pts = [box(1:2) + [0 0];...
              box(1:2) + [0 box(4)];...
              box(1:2) + [box(3) box(4)];...
              box(1:2) + [box(3) 0];
              box(1:2) + [0 0]];
    points(:,:,i) = pts;
end
end
