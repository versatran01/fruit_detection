function [ mask, bbox ] = detectFruit( pixel_model, image, scale )
%DETECTFRUIT Detect fruit in an image.
% `pixel_model` is the detection model trained at the pixel level.
% `image` is the input image in the RGB color space.

% NOTE: all these parameters tuned at scale of 1
if nargin < 3
    scale = 1;
end
areaScale = scale*scale;

% convert to extended color space
image = rgb2fullcs(image);
% calculate the mask with the pixel-level model, then round it
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

% throw away components below a very low threshold of area
large = area > 3*areaScale;
CC.discard(~large);

% get bounding boxes and areas for remaining regions
centroids = CC.Centroid();

% calculate distance between centroids
dist = pdist2(centroids, centroids, 'euclidean');

nearby = dist < 30*scale;     % take the closest that also satisfy the threshold
nearby = triu(nearby,1);    
smallest = smallestNonDiagonal(dist);
nearby = nearby & smallest;

% find those which have not been merged
% and place them back along the diagonal
nearby = nearby | diag(~any(nearby,1));
% merge the groups
CC.merge(nearby);

% now compute overlap ratio of remaining bounding boxes
bbox = CC.BoundingBox();
overlap = bboxOverlapRatio(bbox,bbox,'Min');
overlap = triu(overlap,1);  % take everything above diagonal

% find boxes which overlap more than 30%
overlap = overlap > 0.30;
overlap = overlap | diag(~any(overlap,1));
% merge them...
CC.merge(overlap);

% threshold by area again
%area = CC.Area();
%large = area > 40;
%CC.discard(~large);

mask = CC.image;
bbox = CC.BoundingBox();
end

function [smallest] = smallestNonDiagonal(dist)
%SMALLESTNONDIAGONAL Find the smallest non-diagonal value. For use with 
% pdist2 and similar methods.
% Note: We assume dist is symmetric.
M = size(dist,1);
N = size(dist,2);
% make the (sub-) diagonal nan
dist = triu(dist,1) + tril(NaN(M,N));
[~,small] = min(dist, [], 1); % column-wise min for smallest (ignoring nan)
% convert to logical 2D indices
ind = sub2ind(size(dist),small,1:numel(small));
smallest = false(size(dist));
smallest(ind) = true;
smallest(1,1) = false;
end
