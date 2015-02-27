function [ mask ] = detectPixels( image, descriptors, model )
%DETECTPIXELS Apply descriptors to an image and then classify pixels in the
% enhanced descriptor feature space.
% `image` is an input image.
% `descriptors` is a cell array of descriptor structures.
% `model` is the result of a tuning method (libSVM, libLinear, etc)
if numel(descriptors) ~= 1
    error('Only one level of descriptors is currently supported');
end
% filter the image
resp = applyDescriptors(image, descriptors{1});
% convert to a set of observations in row
end
