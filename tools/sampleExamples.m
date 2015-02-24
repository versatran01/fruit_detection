function [ Xpos, Xneg ] = sampleExamples( image, selections, masks, ...
    ratio )
%SAMPLEEXAMPLES Sample examples (pixel level) from an
% image. The size of the feature-space will be equal to the number of 
% channels in the image.
% `image` is input image.
% `selections` are selections from dataset.
% `masks` are masks from dataset.
% `ratio` is ratio of negative to positive examples.
C = size(image, 3);
image = im2double(image);
% create two large masks - one for positive and one for negative
sz = size(image);
[mask_pos,mask_neg] = createLargeMask(sz, selections, masks);
mask_pos = logical(mask_pos);
mask_neg = ~logical(mask_neg);  % flip here to get negative mask
% sample positive examples
npos = nnz(mask_pos);
Xpos = zeros(npos,C);
for i=1:C
    chan = image(:,:,i);
    chan = chan(mask_pos);
    Xpos(:,i) = chan;
end
% sample negative examples
nneg = npos*ratio;
Xneg = zeros(nneg,C);
% generate sample positions for negative examples
idx = find(mask_neg);
idx = idx(randperm(numel(idx)));
idx = idx(1:nneg);
% extract negatives
for i=1:C
    chan = image(:,:,i);
    chan = chan(idx);
    Xneg(:,i) = chan;
end
end
