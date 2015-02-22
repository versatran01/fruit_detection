function saveImagesToPath( images, path, prefix )
%SAVEIMAGESTOPATH Save a cell array of images to a directory.
if ~exist(path,'dir')
    error('Directory %s does not exist!', path);
end
N = numel(images);
numdigits = numel(num2str(N));  % number of digits
numformat = sprintf('%%.%ii',numdigits);
format = sprintf('%%s/%%s%s.png', numformat);
for i=1:numel(images)
    I = images{i};
    fullpath = sprintf(format, path, prefix, i);
    imwrite(I,fullpath);
end
end
