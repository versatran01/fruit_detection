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

% fill image regions and holes
mask = imfill(mask, 'holes');

CC = bwconncomp(mask);

properties = regionprops(CC, 'Area', 'BoundingBox', 'Centroid', ...
                         'MajorAxisLength', 'MinorAxisLength');
area = [properties.Area];
major_axis_length = [properties.MajorAxisLength];
minor_axis_length = [properties.MinorAxisLength];
axis_ratio = major_axis_length ./ minor_axis_length;
bbox = vertcat(properties.BoundingBox);

% throw away the pixels below the treshold
idx = (area > 20) & (area < 500) & (axis_ratio < 2);
strip = cell2mat( CC.PixelIdxList(~idx)' );
mask(strip) = false;

% get bounding boxes
bbox = bbox(idx,:);
end
