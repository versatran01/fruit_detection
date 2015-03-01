function [ bigMask ] = createLargeMask( dims, selections,...
    masks, varargin )
%CREATELARGEMASK Create a large image mask from a set of small selections
% and small region masks.
% `dims` is the size of the image [rows,cols].
% `selections` is cell array of selections.
% `masks` is cell array of masks, one per selection.
% `scale` is the scale factor being applied to the selections/masks
defaults.scale = 1;
defaults.fillEmpty = true;
defaults.warnOnEmptyMask = true;
defaults.filter = [];
options = propval(varargin, defaults);

bigMask = false(dims(1), dims(2));
N = numel(selections);
if numel(masks) ~= N
    error('selections and masks must have same number of cells');
end
for i=1:N
    sel = selections{i};
    if ~isempty(options.filter)
        % we are filtering by selection type
        if sel(4) ~= options.filter
            continue;
        end
    end
    [tl,wh] = regionForSelection(sel, dims, options.scale);
    msk = logical(masks{i});
    if isempty(msk)
        if ~options.fillEmpty
            continue;
        end
        if options.warnOnEmptyMask
            warning('A mask was empty, using full region!');
        end
        % generate circular mask
        msk = false(wh(2)+1, wh(1)+1);
        xvals = 1:size(msk,2);  % col indices
        yvals = 1:size(msk,1);  % row indices
        
        xvals = reshape(xvals,1,numel(xvals));
        xvals = repmat(xvals,numel(yvals),1);
        xvals = xvals(:);
        yvals = reshape(yvals,numel(yvals),1);
        yvals = repmat(yvals,size(msk,2),1);
        
        % find points inside the selection region
        % todo: for now we assume circular, add other selections later...
        coords = [xvals yvals];
        center = sel(1:2)*options.scale - tl;
        dists = bsxfun(@minus,coords,center);
        dists = sqrt( sum(dists.^2, 2) );
        inside = dists < sel(3)*options.scale;
        msk(inside) = true;
    else
        sz = size(msk);
        sz = sz([2 1]); % width, height order
        % check if mask needs resizing
        if any(sz ~= wh+1)
            if options.scale==1
                error('Scale is 1 but mask resizing is required, this should not happen');
            end
            msk = imresize(msk,[wh(2)+1 wh(1)+1],'nearest');
        end
    end
    % apply to big mask:
    irow = tl(2):(tl(2)+wh(2)); % y indices
    icol = tl(1):(tl(1)+wh(1)); % x indices
    bigMask(irow,icol) = bigMask(irow,icol) | msk;
end
end
