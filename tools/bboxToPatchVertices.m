function [ X, Y ] = bboxToPatchVertices( bbox )
%BBOXTOPATCHVERTICES 
if isempty(bbox)
    points = [];
    return;
end
N = size(bbox,1);
if size(bbox,2) ~= 4
    error('bbox must be Nx4');
end

X = zeros(4, N);
Y = zeros(4, N);

for i = 1:N
    box = bbox(i, :);
    X(:, i) = [box(1); box(1) + box(3); box(1) + box(3); box(1)];
    Y(:, i) = [box(2); box(2); box(2) + box(4); box(2) + box(4)];
end

end

