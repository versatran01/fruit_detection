function test_tracker()
close all
load('models/cs_svc.mat');
if ismac()  % terrible hack :P
    bag = ros.Bag('/Volumes/D512/ground/rectified/r1s_2015-03-09-15-33-01.bag');
else
    bag = ros.Bag('/home/chao/Workspace/bag/booth/r1s_steadicam_v5_2015-02-18-11-56-32.bag');
end
topic = '/color/image_rect_color';
use_pause = true;
plot_tracker = true;
plot_detections = false;
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

CCprev = [];
imagePrev = [];
detectionPlotter = DetectionPlotter();

while bag.hasNext()
    [msg, meta] = bag.read();
    if ~strcmp(meta.topic, topic), continue; end
    
    image = rosImageToMatlabImage(msg);
    scale = 0.5;
    image = imresize(image, scale);
    image = flipud(image);
    
    CC = detectFruit(model, image, scale);
    
    % plot detections side by side
    if ~isempty(CCprev)
        detectionPlotter.setFrame(imagePrev,CCprev,image,CC);
    end
    CCprev = CC;
    imagePrev = image;
    
    tracker.track(CC, image);
    
    if plot_detections
        im_handles(1) = plotImageOnAxes(ax_handles(1), ...
                                        im_handles(1), image);
        %set(ax_handles(1), 'YDir', 'normal');
        
        
        patch_handle = plotBboxesOnAxes(ax_handles(1), patch_handle, ...
                                        CC.BoundingBox, 'r');
        
        % mask
        im_handles(2) = plotImageOnAxes(ax_handles(2), ...
                                        im_handles(2), CC.image);
        %set(ax_handles(2), 'YDir', 'normal');
    end
    fprintf('Processed image %i\n', image_count);
    image_count = image_count+1;
    drawnow;
    if use_pause, pause; end
end
end