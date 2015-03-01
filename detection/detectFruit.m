function [ mask ] = detectFruit( pixel_model, image )
%DETECTFRUIT Detect fruit in an image.
% `pixel_model` is the detection model trained at the pixel level.
% `image` is the input image in the RGB color space.

% convert to extended color space
image = rgb2fullcs(image);
% calculate the mask with the pixel-level model
mask = detectPixels(pixel_model, image);

% todo: connected components, etc...
mask = mask > 0.5;
CC = bwconncomp(mask);

area = regionprops(CC,'Area');
area = [area.Area];

idx = area > 15;

strip = cell2mat( CC.PixelIdxList(~idx)' );
mask(strip) = false;

end
