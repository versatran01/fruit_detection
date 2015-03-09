function test_tracker()
close all
load('models/cs_svc.mat');
if ismac()  % terrible hack :P
    bag = ros.Bag('/Volumes/D512/ground/south/r1s_steadicam_v5_2015-02-18-11-56-32.bag');
else
    bag = ros.Bag('/home/chao/Workspace/bag/booth/r1s_steadicam_v5_2015-02-18-11-56-32.bag');
end
use_pause = true;
plot_tracker = true;
plot_detections = true;
bag.resetView(bag.topics);
tracker = FruitTracker(plot_tracker);

if plot_detections
    figure(1);
    ax_handles(1) = subplot(1,2,1);
    ax_handles(2) = subplot(1,2,2);
    im_handles = gobjects(2, 1);
    patch_handle = gobjects(1);
end
image_count = 1;

while bag.hasNext()
    [msg, meta] = bag.read();
    if ~strcmp(meta.topic, '/color/image_raw'), continue; end
    
    image = rosImageToMatlabImage(msg);
    scale = 0.5;
    image = imresize(image, scale);
    
    CC = detectFruit(model, image, scale);
    
    tracker.track(CC, image);
    
    if plot_detections
        im_handles(1) = plotImageOnAxes(ax_handles(1), ...
                                        im_handles(1), image);
        set(ax_handles(1), 'YDir', 'normal');
        
        
        patch_handle = plotBboxOnAxes(ax_handles(1), patch_handle, ...
                                      CC.BoundingBox, 'r');
        
        % mask
        im_handles(2) = plotImageOnAxes(ax_handles(2), ...
                                        im_handles(2), CC.image);
        set(ax_handles(2), 'YDir', 'normal');
    end
    fprintf('Processed image %i\n', image_count);
    image_count = image_count+1;
    drawnow;
    if use_pause, pause; end
end
end

function handle = plotImageOnAxes(ax, handle, image)
if ~isgraphics(handle)
    disp('Creating new image handle');
    handle = imshow(image, 'Parent', ax);
else
    set(handle, 'CData', image);
end
end

function handle = plotBboxOnAxes(ax, handle, bboxes, color)
[X, Y] = bboxToPatchVertices(bboxes);
if ~isgraphics(handle)
    disp('Creating new patch handle')
    handle = patch(X, Y, 'y', 'Parent', ax, ...
                   'EdgeColor', color, 'FaceAlpha', 0.1);
else
    set(handle, 'XData', X, 'YData', Y);
end
end
