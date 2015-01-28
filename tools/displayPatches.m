function [ hImg ] = displayPatches( patches, normalize )
%DISPLAYPATCHES Display patches using imshow.
% Patches must be DxDxCxN
if nargin < 2
    normalize = false;
end
N = size(patches,4);
ncols = floor(sqrt(N));
nrows = ceil(N/ncols);
dims = [nrows ncols];
% create an image of the patches
if normalize
    patches = normalizeData(patches);
end
I = assemblePatches(patches,dims,1);
hImg = imshow(I);
end
