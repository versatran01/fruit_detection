function [ Xpos, Xneg ] = sampleExamples( image, selections, masks, ...
   scale )
%SAMPLEEXAMPLES Sample examples (pixel level) from an
% image. The size of the feature-space will be equal to the number of 
% channels in the image.
% `image` is input image.
% `selections` are selections from dataset.
% `masks` are masks from dataset.
C = size(image, 3);
image = im2double(image);
% create two large masks - one for positive and one for negative
sz = size(image);

% mask fruit
mask_pos = createLargeMask(sz, selections, masks,...
    'scale', scale, 'filter', 1);
% mask non-fruit
mask_neg = createLargeMask(sz, selections, masks,...
    'scale', scale, 'filter', 2, 'warnOnEmptyMask', false);
mask_pos = logical(mask_pos);
mask_neg = logical(mask_neg);

% sample positive examples
npos = nnz(mask_pos);
Xpos = zeros(npos,C);
for i=1:C
    chan = image(:,:,i);
    chan = chan(mask_pos);
    Xpos(:,i) = chan;
end
% negative
nneg = nnz(mask_neg);
Xneg = zeros(nneg,C);
for i=1:C
    chan = image(:,:,i);
    chan = chan(mask_neg);
    Xneg(:,i) = chan;
end
end
