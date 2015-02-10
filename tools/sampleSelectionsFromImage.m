function [ subImages ] = sampleSelectionsFromImage( image, selections )
%SAMPLESELECTIONSFROMIMAGE Sample a cell array of selections from an
% image to create many small sub-images. (Selections are circular).
subImages = cell(numel(selections), 1);
for i=1:numel(selections)
    circ = selections{i};
    % convert to square
    tl = circ(1:2) - circ(3);  % top left
    br = circ(1:2) + circ(3);  % bottom right
    tl = floor(tl);
    br = ceil(br);
    % clamp to size of image
    dims = size(image);
    tl = max(tl, 1);
    br = min(br, dims([2 1]));
    % check if we still have a square
    if prod(br - tl)==0
        % no area...
        subImages{i} = [];
    else
        subImages{i} = imcrop(image,[tl br-tl]);
    end    
end
end
