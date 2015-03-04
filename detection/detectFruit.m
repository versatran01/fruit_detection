function [ mask, bbox ] = detectFruit( pixel_model, image )
%DETECTFRUIT Detect fruit in an image.
% `pixel_model` is the detection model trained at the pixel level.
% `image` is the input image in the RGB color space.

% NOTE: all these parameters tuned at scale of 1

% convert to extended color space
image = rgb2fullcs(image);
% calculate the mask with the pixel-level model
mask = detectPixels(pixel_model, image);
mask = mask > 0.5;

% fill holes
mask = imfill(mask,'holes');

% erode a bit
se = strel('disk', 1);
mask = imerode(mask, se);

% find connected components
CC = ConnectedComponents(mask);

% find properties of connected components
area = CC.Area();
bbox = CC.BoundingBox();
centroids = CC.Centroid();

% throw away components below a very low threshold of area
large = area > 3;
CC.discard(~large);

% get bounding boxes and areas for remaining regions
area = area(large,:);
bbox = bbox(large,:);
centroids = centroids(large,:);

% calculate distance between centroids
dist = pdist2(centroids, centroids, 'cityblock');

nearby = dist < 30;
nearby = triu(nearby,1);    % take everything above the diagonal only
[row,col] = find(nearby);

[unique_rows,ia,ic] = unique(row);

% row,col are now groups we should form


end
