function [ CC, counts, circles ] = detectFruit( pixel_model, image, scale )
%DETECTFRUIT Detect fruit in an image.
% `pixel_model` is the detection model trained at the pixel level.
% `image` is the input image in the RGB color space.

% NOTE: all these parameters tuned at scale of 1

% Values above `mask_threshold` are set to 1 in the mask.
params.mask_threshold = 0.5;
% Size of the erosion filter to apply before processing.
params.erode_size = 0;
% Minimum filled number of pixels to retain a blob.
params.area_thresh = 5;
% Distance between centroids below which merging will occur (once).
params.merge_distance_thresh = 30;
% Minimum bbox overlap required to trigger merging of blobs.
params.merge_overlap_thresh = 0.2;
% Minimum number of edge points required to attempt fitting (pixels).
params.min_edge_points = 20;
% Minimum number of inliers required to fit a circle (pixels).
params.min_inliers_absolute = 6;
% Minimum number of inliers required to fit a circle (percentage).
params.min_inliers_frac = 0.03; % 0.03
% Total max iterations allowed when fitting circles.
params.max_iterations_absolute = 300000;
% Inlier threshold when fitting, in pixels.
params.inlier_threshold = 8; % 10
% Number of successful fits to trigger early exit.
params.early_exit_threshold = 500;
% Threshold below which circles are merged when fitting.
params.circle_merge_threshold = 3;
% Ratio of circle radius to mask size that triggers elimination.
params.circle_max_radius_ratio = 1.5;
% Absolute size below which circles are eliminated (pixels).
params.circle_min_radius = 8;
% Max displacement of the circle center from edge of box, as fraction of
% circle radius.
params.circle_max_displacement = 0.5;
% Absolute min 'inlier score' required in the circle fit
params.circle_min_inlier_score = 0;
% Fraction of circle which must be filled with positive pixels.
params.circle_min_fill_ratio = 0.35;
% Minimum amount of a bbox which must be filled by circles.
params.min_bbox_circle_frac = 0.1;
% Enables some debug-only components.
params.debug = false;

if nargin < 3
    scale = 1;
end
areaScale = scale*scale;

% convert to extended color space
image_full = rgb2fullcs(image);
% calculate the mask with the pixel-level model, then round it
mask = detectPixels(pixel_model, image_full);
mask = mask > params.mask_threshold;

% fill holes
mask = imfill(mask,'holes');

% erode a bit
if params.erode_size
    se = strel('disk', params.erode_size);
    mask = imerode(mask, se);
end

% find connected components
CC = ConnectedComponents(mask);

% throw away components below a very low threshold of area
area = CC.Area();
large = area > ceil(params.area_thresh * areaScale);
CC.discard(~large);

% calculate distance between centroids
centroids = CC.Centroid();
dist = pdist2(centroids, centroids, 'euclidean');

nearby = dist < params.merge_distance_thresh * scale;
nearby = triu(nearby,1);    
smallest = smallestDistance(dist);
nearby = nearby & smallest;
% find those which have not been selected
% and place them back along the diagonal
nearby = nearby | diag(~any(nearby,1));
% merge the groups
CC.merge(nearby);

% now compute overlap ratio of remaining bounding boxes
while true && ~CC.isempty()
    % sort big to small    
    bbox = CC.BoundingBox();
    [~,idx] = sort(bboxArea(bbox), 'descend');
    bbox = bbox(idx,:);
    CC.reorder(idx);
    
    overlap = bboxOverlapRatio(bbox, bbox, 'Min');
    overlap = triu(overlap,1);  % take everything above diagonal

    % find boxes which overlap more than some percentage
    overlap = overlap > params.merge_overlap_thresh;
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
[CC,counts,circles] = segmentComponents(CC, image, scale, params);
end
