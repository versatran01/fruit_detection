function [ X, Y ] = bboxToPatchVertices(bboxes)
%BBOXTOPATCHVERTICES 
if isempty(bboxes)
    X = [];
    Y = [];
    return;
end

if size(bboxes, 2) ~= 4
    error('bboxes must be Nx4');
end

X = [bboxes(:, 1), bboxes(:, 1) + bboxes(:, 3), bboxes(:, 1) + bboxes(:, 3), bboxes(:, 1)]';
Y = [bboxes(:, 2), bboxes(:, 2), bboxes(:, 2) + bboxes(:, 4), bboxes(:, 2) + bboxes(:, 4)]';

end

