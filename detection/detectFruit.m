function [ CC ] = detectFruit( pixel_model, image, scale )
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
large = area > ceil(3*areaScale);
CC.discard(~large);

% get bounding boxes and areas for remaining regions
centroids = CC.Centroid();

% calculate distance between centroids
dist = pdist2(centroids, centroids, 'euclidean');

nearby = dist < 30*scale;     % take the closest that also satisfy the threshold
nearby = triu(nearby,1);    
smallest = smallestDistance(dist);
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
area = CC.Area();
large = area > 100*areaScale;
CC.discard(~large);

area = CC.Area();
bbox = CC.BoundingBox();

% iterate over the remaining regions
circles = cell(CC.size(), 1);
for i=1:CC.size()
    if area(i) > 300*areaScale
        % pull out the mask region and the original image area (for
        % debugging)
        original = imcrop(image(:,:,1:3), bbox(i,:));
        submask = imcrop(CC.image, bbox(i,:));
        X = segmentFruit(original,submask);
        if ~isempty(X)
            % adjust to position of the bbox
            X(:,1:2) = bsxfun(@plus, X(:,1:2), bbox(i,1:2));
            circles{i} = X;
        end
    end
end
% included in return value...
CC.circles = circles;
end
