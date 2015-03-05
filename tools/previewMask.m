function [ hPlots ] = previewMask( original, mask )
%PREVIEWMASK Preview an image with a transparent mask on top of it.
maskColor = [0 0.75 1];
maskAlpha = 0.4;
dims = size(original);
dims = dims(1:2);
if any(size(mask) ~= dims)
    error('image and mask must have same size');
end
% create solid mask
for i=1:3
    solid(:,:,i) = ones(dims)*maskColor(i);
end
% plot image with solid mask on top
hPlots(1) = imshow(original);
hold on;
hPlots(2) = imshow(solid);
set(hPlots(2),'AlphaData', mask * maskAlpha);
end
