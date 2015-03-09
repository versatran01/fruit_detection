function [ handle ] = plotBboxesOnAxes(ax, handle, bboxes, color, alpha, width)
if nargin < 6, width = 1; end
if nargin < 5, alpha = 0.1; end
if size(bboxes, 2) ~= 4, error('Invalid bounding box size'); end

[X, Y] = bboxToPatchVertices(bboxes);
if isempty(handle) || ~isgraphics(handle)
    disp('Creating new patch handle')
    handle = patch(X, Y, 'y', ...
                   'Parent', ax, ...
                   'EdgeColor', color, ...
                   'FaceAlpha', alpha, ...
                   'LineWidth', width);
else
    set(handle, 'XData', X, 'YData', Y);
end
end

