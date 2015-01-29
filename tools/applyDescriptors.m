function [ responses ] = applyDescriptors( image, descriptors )
%APPLYDESCRIPTORS Calculate descriptor responses on image.
scale = descriptors.scale;
weights = descriptors.weights;
if size(image,3) == 3
    image = rgb2gray(image);
end
image = im2double(imresize(image,scale));
% TODO: for now assume monochrome images (fix this later)!
responses = zeros(size(image, 1), size(image, 2), size(weights, 2));
sig = @(z)(1 ./ (1 + exp(-z)));
for d=1:size(weights,4)
    h = weights(:,:,:,d);
    h = rot90(h,2); % equivalent to fliplr and flipud
    resp = imfilter(image,h);
    responses(:,:,d) = sig(resp);
end
end
