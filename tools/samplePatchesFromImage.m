function [patches] = samplePatchesFromImage(image, D, N)
%SAMPLEPATCHESFROMIMAGE - Sample N patches (size DxD) from an image at 
% random.
imgDim = size(image);
if any(imgDim(1:2) < D)
    error('Patch size is too large for this image');
end
if numel(imgDim) > 2
    chan = imgDim(3);
else
    chan = 1;
end
patches = zeros(D,D,chan,N);
for n=1:N
    % select random PATCH_SIZExPATCH_SIZE patch within image
    x = randi(imgDim(2)-D);
    y = randi(imgDim(1)-D);
    patch = image(y:(y+D-1), x:(x+D-1), :);
    patches(:,:,:,n) = patch;
end
end
