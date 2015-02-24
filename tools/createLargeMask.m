function [ bigMask ] = createLargeMask( dims, selections, masks )
%CREATELARGEMASK Create a large image mask from a set of small selections
% and small region masks.
% `dims` is the size of the image [rows,cols].
% `selections` is cell array of selections.
% `masks` is cell array of masks, one per selection.
bigMask = false(dims(1), dims(2));
N = numel(selections);
if numel(masks) ~= N
    error('selections and masks must have same number of cells');
end
for i=1:N
    [tl,wh] = regionForSelection(selections{i}, dims);
    msk = logical(masks{i});
    irow = tl(2):(tl(2)+wh(2)); % y
    icol = tl(1):(tl(1)+wh(1)); % x
    bigMask(irow,icol) = bigMask(irow,icol) | msk;
end
bigMask = double(bigMask);
end
