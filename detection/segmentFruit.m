function [ X ] = segmentFruit( original, mask, scale )
%SEGMENTFRUIT Segment fruit in a small mask image.
%   `original` is the RGB space, (used when debugging only).
%   `mask` is the b&w mask extracted by the model.
%
%   Return value X is a Nx3 vector of circles: [x,y,radius]
%   It may be empty, if no circles are found.

% todo: store all parameters in a struct

areaScale = scale*scale;

% find masked pixel edges
mask_pixels = find(edge(mask));
[y,x] = ind2sub(size(mask), mask_pixels);
if size(x,1) < 20*areaScale
    % too few points...
    X = [];
    return;
end

% fit circles
% TODO: these params are tuned at scale of 1
%X = fitCircles([x y], 50000, 10*scale, 0.02, 50, 3*scale);

X = fitCirclesFast([x y], 50000, 10*scale, 0.02, 50, 3*scale);
X = sortrows(X,[4 3]);
X = flipud(X);

if ~isempty(X)
    % eliminate any circles with really big radii
    keep = X(:,3) < max(size(mask));
    X = X(keep,:);
    % eliminate any circles with really small radii
    keep = X(:,3) > 8*scale;
    X = X(keep,:);
    % eliminate circles far outside the bounding box
    center = size(mask) / 2;
    dist = sqrt( sum(bsxfun(@minus, X(:,1:2), center).^2, 2) );
    keep = dist < (norm(center) + X(:,3)*0.1);
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
    end
end
end
