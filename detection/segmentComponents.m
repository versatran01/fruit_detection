function [ CC, counts, circles, indices ] = segmentComponents( CC, original, scale )
%SEGMENTCOMPONENTS Segment fruit inside the connected components.
% Input `CC` is a ConnectedComponents object.
%
% Outputs:
%   `CC` is the same object, with some removed blobs.
%   `counts` is the count of fruit in each blob.
%   `circles` are circles fit to the fruit.
%   `indices` are logical indices to the blobs we chose to keep.

% iterate over the remaining regions
bbox = CC.BoundingBox();
circles = cell(CC.size(), 1);
reject = false(CC.size(), 1);
counts = [];
for i=1:CC.size()
    % pull out the mask region and the original image area
    if ~isempty(original)
        pic = imcrop(original, bbox(i,:));
    else
        pic = [];
    end
    submask = imcrop(CC.image, bbox(i,:));
    X = segmentCircles(pic,submask,scale);
    
    % throw away if the total area of circles is too low
    if sum(X(:,6)) < 0.2
        X = [];
    end
    
    if ~isempty(X)
        % adjust to position of the bbox
        X(:,1:2) = bsxfun(@plus, X(:,1:2), bbox(i,1:2));
        circles{i} = X;
        counts(end+1,:) = size(X,1);
    else
        reject(i) = true;
    end
end
% throw away anything we could not fit a circle to
CC.discard(reject);
circles = circles(~reject);
indices = ~reject;
end
