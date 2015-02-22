function [ images ] = loadImagesAtPaths( paths )
%LOADIMAGESATPATHS Load images at specified paths.
if ~iscell(paths)
    error('Paths must be a cell array');
end
images = cell(numel(paths),1);
for i=1:numel(paths)
    filepath = paths{i};
    images{i} = imread(filepath);
end
end
