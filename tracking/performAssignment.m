function [ assignment, unassignedTracks, unassignedDetections ] = ...
    performAssignment( cost, CC, beta )
%PERFORMASSIGNMENT Given MxN `cost` matrix, find the optimal assignment of
% rows to columns.
% `CC` are the detections in the new image.
%
% M is the dimension of the tracks.
% N is the dimension of the fruits.
%

% todo: try to scale beta using CC.Centroids

if nargin < 3
    beta = 0.4;
end

% find min/max cost per-fruit
cmin = min(cost,[],1);
cmax = max(cost,[],1);

c0 = cmin + (cmax - cmin)*beta;

[assignment, unassignedTracks, unassignedDetections] ...
    = assignDetectionsToTracks( cost, c0 );

end
