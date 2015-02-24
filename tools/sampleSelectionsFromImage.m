function [ samples, regions ] = sampleSelectionsFromImage( image,...
    selections )
%SAMPLESELECTIONSFROMIMAGE Sample a cell array of selections from an
% image to create many small sub-images. (Selections are circular).
samples = cell(numel(selections), 1);
regions = samples;
for i=1:numel(selections)
    circ = selections{i};
    [tl,wh] = regionForSelection(circ, size(image));
    % check if we still have a square
    if prod(wh)==0
        % no area...
        samples{i} = [];
        regions{i} = [];
    else
        samples{i} = imcrop(image,[tl wh]);
        regions{i} = [tl wh];
    end
end
end
