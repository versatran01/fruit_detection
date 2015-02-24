function [ tl, wh ] = regionForSelection( circ, dims )
%REGIONFORSELECTION Calculate square region corresponding to a circular
% selection in the image.
% `circ` is the circle parameters [cx,cy,r]
% `dims` is the size of the image [rows,cols]
tl = circ(1:2) - circ(3);  % top left
br = circ(1:2) + circ(3);  % bottom right
tl = floor(tl);
br = ceil(br);
% clamp to size of image
tl = max(tl, 1);
br = min(br, dims([2 1]));
wh = br - tl;
end
