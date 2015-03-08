function [ CC, counts, circles ] = detectFruit( pixel_model, image, scale )
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

% throw away components below a very low threshold of area
area = CC.Area();
large = area > ceil(3*areaScale);
CC.discard(~large);

% calculate distance between centroids
centroids = CC.Centroid();
dist = pdist2(centroids, centroids, 'euclidean');

nearby = dist < 30*scale;  % take the closest that also satisfy the threshold
nearby = triu(nearby,1);    
smallest = smallestDistance(dist);
nearby = nearby & smallest;
% find those which have not been selected
% and place them back along the diagonal
nearby = nearby | diag(~any(nearby,1));
% merge the groups
CC.merge(nearby);

% now compute overlap ratio of remaining bounding boxes
while true
    % sort big to small
    CC.sort('BoundingArea', 'descend');
    
    bbox = CC.BoundingBox();
    overlap = bboxOverlapRatio(bbox, bbox, 'Min');
    overlap = triu(overlap,1);  % take everything above diagonal

    % find boxes which overlap more than 5%
    overlap = overlap > 0.05;
    if ~any(overlap)
        % no more overlap, stop
        break;
    end
    
    % take the first in each column (ie: only merge into largest)
    [row,col] = find(overlap);
    [col,ia,~] = unique(col);
    row = row(ia);
    ind = sub2ind(size(overlap),row,col);
    overlap = false(size(overlap));
    overlap(ind) = true;
    
    overlap = overlap | diag(~any(overlap,1));
    % merge them...
    CC.merge(overlap);
end

% perform segmentation of blobs...
[CC,counts,circles] = segmentComponents(CC, scale);
end
