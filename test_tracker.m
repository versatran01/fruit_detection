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
        image = rosImageToMatlabImage(msg);
        image = imresize(image, 0.4);
        
        [mask, CC] = detectFruit(model, image);
        [X, Y] = bboxToPatchVertices(CC.BoundingBox);
        
        tracker.track(CC, image);
        
        imshow(image, 'Parent', handles(1));
        set(handles(1), 'YDir', 'normal');
        patch(X, Y, 'r', 'Parent', handles(1), ...
              'EdgeColor', 'r', 'FaceAlpha', '0.1');
        hold on;
        
        % mask
        imshow(mask, 'Parent', handles(2));
        set(handles(2), 'YDir', 'normal');
        drawnow;
    end
end

end
