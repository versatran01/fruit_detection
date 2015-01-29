function [ X ] = prepareData( X, low, high )
%PREPAREDATA Prepare data for auto-encoder.
% Mean shift, followed by clamping into range [low,high].
% Assumed that observations are in columns of X.
if nargin < 3
    low = 0.1;
    high = 0.9;
end
X = bsxfun(@minus, X, mean(X,1));
range = std(X(:)) * 3;
X = max(min(X, range), -range) / range;
X = ((X + 1)/2) * (high-low) + low;
end
