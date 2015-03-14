close all;

bag = ros.Bag('/home/chao/Workspace/bag/booth/r26n_steadicam_v5_2015-03-13-18-50-48_fixed.bag');
topic_name = '/color/image_rect_color';
bag.resetView(bag.topics, bag.time_begin + 102);
load('models/cs_svc.mat');

image_count = 0;
scale = 0.5;

im_handle = gobjects(1);
ax_handle = axes();

tracker = FruitTracker();

option.show_detection_bbox = true;
option.show_predicted_bbox = true;
option.show_track = true;
option.show_last_bbox = true;
option.show_optical_flow = false;

while bag.hasNext()
    [msg, meta] = bag.read();
    if ~strcmp(meta.topic, topic_name), continue; end
    image_count = image_count + 1;
    
    image = rosImageToMatlabImage(msg);
    image = imresize(image, scale);
    
    [CC, counts] = detectFruit(model, image, scale);
    tracker.track(CC, image, counts);
    tracker.visualize(ax_handle, option);
    
    im_handle = plotImageOnAxes(ax_handle, im_handle, image);
    set(ax_handle, 'YDir', 'normal')
    drawnow
    pause
end