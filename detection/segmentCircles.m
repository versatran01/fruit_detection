function [ X ] = segmentCircles( original, mask, scale, params )
%SEGMENTCIRCLES Segment circles (fruit) in a small mask image.
%   `original` is the RGB space, (used when debugging only).
%   `mask` is the b&w mask extracted by the model.
%
%   Return value X is a NxK vector of circles: [x,y,radius,...other shit]
%   It may be empty, if no circles are found.
%
%   Format of X: [x,y,radius,num_inliers,circle_fill_frac,box_fill_frac]

% todo: store all parameters in a struct

X = zeros(0,6);
if any(size(mask) <= 3)
    return; % mask too small to convolve
end

% approximate edge finder, much faster than built in `edge`
mask_edges = conv2(double(mask), [1 1 1; 1 0 1; 1 1 1], 'full') / 8;
mask_edges = mask_edges >= 5/8 & mask_edges < 1;
mask_pixels = find(mask_edges);

[y,x] = ind2sub(size(mask_edges), mask_pixels);
points = [x y];
% subtract padding from the conv2 operation
points = bsxfun(@minus,points,[1 1]);

num_points = size(points,1);
if num_points < max( params.min_edge_points * scale, params.min_inliers_absolute )
    % too few points, we can't fit this very well
    return;
end

% N choose K, or max iterations absolute - whichever comes first
num_iters = min( nchoosek(num_points, 3), params.max_iterations_absolute );

% either percentage or minimum inliers, whichever is bigger
inlier_frac = max( params.min_inliers_absolute / num_points, ...
    params.min_inliers_frac );

X = fitCirclesFast(points, num_iters, params.inlier_threshold * scale, ...
    inlier_frac, params.early_exit_threshold, ... 
    params.circle_merge_threshold * scale * scale);

% sort by inliers and then by size
X = sortrows(X,[4 3]);
X = flipud(X);

if ~isempty(X)
    % eliminate any circles with really big radii
    keep = X(:,3) < geomean(size(mask)) * params.circle_max_radius_ratio;
    X = X(keep,:);
    
    % eliminate any circles with really small radii
    keep = X(:,3) > params.circle_min_radius * scale;
    X = X(keep,:);
    
    % eliminate circles far outside the bounding box
    center = size(mask) / 2;
    dist = sqrt( sum(bsxfun(@minus, X(:,1:2), center).^2, 2) );
    % far here defined as 50% the radius
    keep = dist < (norm(center) + X(:,3) * params.circle_max_displacement);
    X = X(keep,:);
    
    % eliminate circles under the min total inliers
    keep = X(:,4) > params.circle_min_inlier_score;
    X = X(keep,:);
    
    % merge remaining circles
    N = size(X,1);
    if N ~= 0
        % find intersecting circles (apply scale factor to radius)
        rads1 = repmat(X(:,3)', N, 1);
        rads2 = repmat(X(:,3), 1, N);
        rads = max(rads1,rads2) * 1.2;
        dist = pdist2(X(:,1:2), X(:,1:2), 'euclidean');
        % symmetric logical matrix
        inside = dist < rads;
        inside = triu(inside,1);
        % best circles (those which have NOT been intersected with one with a
        % better score)
        inside = ~any(inside, 1);
        X = X(inside, :);
        
        % calculate circle area
        area = X(:,3).^2 * pi;
        boxArea = numel(mask);
        
        % get all pixels that are full
        mask_pixels = find(mask);
        [y,x] = ind2sub(size(mask), mask_pixels);
        points = [x y];
        
        % calculate the fill rate of all circles
        inside = pointsInCircles(X(:,1:3), points);
        inside = sum(inside, 2);        % total number of points inside circle
        X = horzcat(X, inside ./ area); % col 5
        
        % calculate area of circles over area of box
        X = horzcat(X, area ./ boxArea); % col 6
        
        % throw away if circle fill ratio below threshold
        keep = X(:,5) > params.circle_min_fill_ratio;
        X = X(keep,:);
    end
end
if isempty(X)
    X = zeros(0,6);
end
end
