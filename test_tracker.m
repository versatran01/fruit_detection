function test_tracker()
load('models/cs_svc.mat');
bag = ros.Bag('/home/chao/Workspace/bag/booth/r1s_steadicam_v5_2015-02-18-11-56-32.bag');
bag.resetView(bag.topics);
tracker = FruitTracker();

figure(1);
handles(1) = subplot(1,2,1);
handles(2) = subplot(1,2,2);

while bag.hasNext()
    [msg, meta] = bag.read();
    if strcmp(meta.topic, '/color/image_raw')
        % todo: add time control
        image = rosImageToMatlabImage(msg);
        process_image(model, image, tracker, handles);
        drawnow;
        pause(0.001);
    end
end

end

function process_image(model, image, tracker, handles)
image = imresize(image, 0.4);
[mask, CC] = detectFruit(model, image);
[X, Y] = bboxToPatchVertices(CC.BoundingBox);
tracker.track(CC, image);

imshow(image, 'Parent', handles(1));
set(handles(1), 'YDir', 'normal');
h_bboxes = patch(X, Y, 'r', 'Parent', handles(1));
set(h_bboxes, 'EdgeColor', 'r');
set(h_bboxes, 'FaceAlpha', '0.1');
imshow(mask, 'Parent', handles(2));
set(handles(2), 'YDir', 'normal');
drawnow
end
