function [ subimages ] = sampleBoundingBoxes( image, bboxes )
%SAMPLEBOUNDINGBOXES Get a set of bounding boxes from an image.
N = size(bboxes,1);
if size(bboxes,2) ~= 4
    error('Invalid bbox dimensions, should be Nx4');
end
subimages = cell(N,1);
for i=1:N
    subimages{i} = imcrop(image, bboxes(i,:));
end
end
