function [ mask, bbox ] = detectFruit( pixel_model, image )
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

properties = regionprops(CC,'Area','BoundingBox','Centroid');
area = [properties.Area];
bbox = vertcat(properties.BoundingBox);

% throw away the pixels below the treshold
idx = area > 40;
strip = cell2mat( CC.PixelIdxList(~idx)' );
mask(strip) = false;

% get bounding boxes
bbox = bbox(idx,:);

% todo: more stuff

end
