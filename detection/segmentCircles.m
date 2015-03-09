function [ X ] = segmentCircles( original, mask, scale )
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
if any(size(mask) <= 3*scale)
    return; % mask too small to work with
end

% pad the image a bit
mask_padded = padarray(mask,[2 2]);    % adds 2 pixels on left,right,top,bottom

% find masked pixel edges
%mask_edges = edge(mask_padded);

% approximate edge finder, much faster than built in `edge`
mask_edges = imfilter(double(mask_padded),[1 1 1; 1 0 1; 1 1 1]) / 8;
mask_edges = mask_edges >= 5/8 & mask_edges < 1;
mask_pixels = find(mask_edges);

[y,x] = ind2sub(size(mask_padded), mask_pixels);
points = [x y];
if size(points,1) < 20*scale
    % too few points, we can't fit this very well
    return;
end
% subtract padding
points = bsxfun(@minus,points,[2 2]);

% fit circles by random sampling
num_points = size(points,1);
num_iters = min(nchoosek(num_points, 3), 300000);

% either 3% or 6 inliers, whichever is bigger
inlier_frac = max(6 / num_points, 0.03);

if exist('fitCirclesFast','file') == 3
    X = fitCirclesFast(points, num_iters, 10*scale, inlier_frac, 500, 3*scale*scale);
else
    warning('fitCirclesFast not found. Did you compile your mex?');
    X = fitCircles(points, num_iters, 10*scale, inlier_frac, 500, 3*scale*scale);
end
X = sortrows(X,[4 3]);
X = flipud(X);

if ~isempty(X)
    % eliminate any circles with really big radii
    keep = X(:,3) < geomean(size(mask)) * 1.5;
    X = X(keep,:);
    
    % eliminate any circles with really small radii
    keep = X(:,3) > 8*scale;
    X = X(keep,:);
    
    % eliminate circles far outside the bounding box
    center = size(mask) / 2;
    dist = sqrt( sum(bsxfun(@minus, X(:,1:2), center).^2, 2) );
    % far here defined as 50% the radius
    keep = dist < (norm(center) + X(:,3) * 0.5);
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
        keep = X(:,5) > 0.25;
        X = X(keep,:);
    end
end
if isempty(X)
    X = zeros(0,6);
end
end
