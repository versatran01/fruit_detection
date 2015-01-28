function [ patches, dims ] = sampleUniformPatches( image, D )
%SAMPLEUNIFORMPATCHES Divide image into a set of uniform patches.
sz = size(image);
if any(mod(sz(1:2),D) ~= 0)
    error('Error, image dimensions not divisible by D');
end
dims = sz(1:2) / D;
patches = zeros(D,D,size(image,3),0);
idx = 1;
for row=1:dims(1)
    for col=1:dims(2)
        x = (col-1)*D + 1;
        y = (row-1)*D + 1;
        patches(:,:,:,idx) = image(y:(y+D-1),x:(x+D-1),:);
        idx=idx+1;
    end
end
end
