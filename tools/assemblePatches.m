function [ image ] = assemblePatches( patches, dims, padding )
%ASSEMBLEPATCHES Assemble sample patches into an image for display.
% Patches should be DxDxCxN
if nargin < 3
    padding = 0;
end
D = size(patches,1);
C = size(patches,3);
N = size(patches,4);
imSize = D*dims + (dims - 1)*padding;
image = ones(imSize(1),imSize(2),C);
idx = 1;
for row=1:dims(1)
    for col=1:dims(2)
        if idx > N
            % ran out of patches, stop
            return;
        end
        % write patch to image at correct location
        x = (col-1)*(D+padding) + 1;
        y = (row-1)*(D+padding) + 1;
        image(y:(y+D-1),x:(x+D-1),:) = patches(:,:,:,idx);
        idx=idx+1;
    end
end
end
