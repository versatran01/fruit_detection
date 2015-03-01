function [ responses ] = applyDescriptors( image, descriptors )
%APPLYDESCRIPTORS Calculate descriptor responses on image.
scale = descriptors.scale;
weights = descriptors.weights;
if scale ~= 1
    image = imresize(image, scale);
end
image = im2double(image);
channels = size(image, 3);
sig = @(z)(1 ./ (1 + exp(-z))); % sigmoid activation function

responses = zeros(size(image, 1), size(image, 2),...
    size(weights, 2));
x = zeros(size(image, 1), size(image, 2), 3);
for d=1:size(weights,4)
    h = weights(:,:,:,d);
    h = rot90(h, 2); % equivalent to fliplr and flipud
    % filter channels separately
    for c=1:channels
        x(:,:,c) = imfilter(image(:,:,c), h(:,:,c));
    end
    responses(:,:,d) = sum(x,3) / 3;
end
end
