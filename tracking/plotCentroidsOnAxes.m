function handle = plotCentroidsOnAxes(ax, handle, centroids, line_spec, width)
if nargin < 6, width = 1; end
if isempty(centroids), return; end
if isempty(handle) || ~isgraphics(handle)
    hold(ax, 'on');
    handle = plot(ax, centroids(:, 1), centroids(:, 2), line_spec, ...
                  'LineWidth', width);
    hold(ax, 'off');
else
    set(handle, 'XData', centroids(:, 1), 'YData', centroids(:, 2));
end

end

