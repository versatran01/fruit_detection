function handle = plotImageOnAxes(ax, handle, image)
if isempty(handle) || ~isgraphics(handle)
    disp('Creating new image handle');
    handle = imshow(image, 'Parent', ax);
else
    set(handle, 'CData', image);
end
end

