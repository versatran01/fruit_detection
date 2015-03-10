function [dist] = trackDetectionDistance(tracks, CC, alpha, varargin)
% TRACKDETECTIONDISTANCE Calculate distance between tracks and a new set of
%   connected components.
% Returns an MxN matrix, where M is the size of tracks and N is the size
% of CC.
%
% Params:
%  `alpha` should be a Mx1 vector of weights in [0,1]. This term
%  interpolates distance cost between the previous and predicted centroid.

defaults.norm = 'euclidean';    % norm to use
options = propval(varargin, defaults);

M = numel(tracks);
if size(alpha, 1) ~= M || size(alpha, 2) ~= 1
    error('Size of weights must be Mx1');
end
if any(alpha < 0 | alpha > 1)
    error('alphas must be bounded by [0,1]');
end

% weights
w = [alpha 1-alpha];

c0_pred = vertcat(tracks.predicted_centroid);
c0_prev = vertcat(tracks.prev_centroid);
c1 = CC.Centroid(); % <- position in new image

dist = bsxfun(@times, pdist2(c0_pred, c1, options.norm), w(:,1)) + ...
       bsxfun(@times, pdist2(c0_prev, c1, options.norm), w(:,2));
end
