function [ X ] = createDetectionFeatures( CC, circles )
%CREATEDETECTIONFEATURES Convert a CC + circles into observations.
N = CC.size();
if numel(circles) ~= N
    error('Size of CC and circles must match!');
end

% compute some parameters
bbox = CC.BoundingBox();
area = CC.Area();
aspect = bbox(:,3) ./ bbox(:,4);            % aspect ratio of bbox
fill = area ./ (bbox(:,3) .* bbox(:,4));     % fraction filled

X = zeros(N,7);
X(:,1) = aspect;
X(:,2) = fill;
X(:,3) = area;

for i=1:N
    circ = circles{i};
    
    % median radius over bbox size
    X(i,4) = median(circ(:,3)) / max(bbox(i,3:4));
    
    % max inliers
    X(i,5) = max(circ(:,4));
    
    % max fill of circles
    X(i,6) = max(circ(:,5));
    
    % area fill of bbox inside circles
    X(i,7) = sum(circ(:,6));
end
end
