function [ mask ] = detectPixels( image, descriptors, model )
%DETECTPIXELS Apply descriptors to an image and then classify pixels in the
% enhanced descriptor feature space.
% `image` is an input image.
% `descriptors` is a cell array of descriptor structures.
% `model` is the result of a tuning method (libSVM, libLinear, etc)
if numel(descriptors) ~= 1
    error('Only one level of descriptors is currently supported');
end
D = size(descriptors{1}.weights, 4);
if model.dimension ~= D
    error('This model was trained on a different dimension');
end
% filter the image
sz = size(image);
N = prod(sz(1:2));  % number of pixels
X = applyDescriptors(image, descriptors{1});
% convert to a set of observations in rows [NxD]
X = reshape(X,N,size(X,3));
% generate labels (assume for now these are simply 1/0)
Y = model.predict(model.model, X);
% convert into mask
mask = logical(reshape(Y,sz(1),sz(2)));
end
