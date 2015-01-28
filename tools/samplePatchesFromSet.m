function [patches] = samplePatchesFromSet(images, D, N, varargin)
%SAMPLEPATCHESFROMSET Sample random patches from a set of images.
% images should be a cell array of matrices with the same number of
% channels.
defaults.mono = false;
defaults.scale = 1;
options = propval(varargin, defaults);
% randomly select images
indices = randi(numel(images),N,1);
% get number of channels in the image set
patches = [];
for i=1:numel(images)
    sampleCount = nnz(indices == i);
    image = images{i};
    if options.mono && size(image,3) > 1
       % convert to monochrome
       image = rgb2gray(image); 
    end
    if options.scale ~= 1
        image = imresize(image, options.scale);
    end
    if isempty(patches)
        patches = zeros(D,D,size(image,3),0);
    end
    % sample 'sampleCount' patches from this image
    P = samplePatchesFromImage(im2double(image),D,sampleCount);
    patches = cat(4,patches,P);
end
end
