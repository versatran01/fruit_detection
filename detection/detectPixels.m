function [ mask ] = detectPixels( model, image )
%DETECTPIXELS Classify pixels using a model.
% `model` is an argument compatible with predictAll().
% `image` is an image of HxWxD dimensions, where D is the size of the
% feature space.
sz = size(image);
N = prod(sz(1:2));  % number of pixels
D = sz(3);  % number of features
% convert to a set of observations in rows [NxD]
X = reshape(image,N,D);
% generate labels (these fall in [0,1] range)
Y = predictAll(model, X);
% convert into mask
mask = reshape(Y, sz(1), sz(2));
end
