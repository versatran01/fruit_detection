function test_tracker()
close all
load('models/cs_svc.mat');
%bag = ros.Bag('/home/chao/Workspace/bag/booth/r1s_steadicam_v5_2015-02-18-11-56-32.bag');
bag = ros.Bag('/Volumes/D512/ground/south/r1s_steadicam_v5_2015-02-18-11-56-32.bag');
% bag = ros.Bag('/home/chao/Workspace/bag/booth/r13n_steadicam_v5_2015-02-18-19-53-00.bag');
bag.resetView(bag.topics);
tracker = FruitTracker();

figure(1);
handles(1) = subplot(1,2,1);
handles(2) = subplot(1,2,2);
imhandles = {[],[]};
patchhandle = [];
count = 1;

while bag.hasNext()
    [msg, meta] = bag.read();
    if strcmp(meta.topic, '/color/image_raw')
        image = rosImageToMatlabImage(msg);
        scale = 0.2;
        image = imresize(image, scale);
        
        CC = detectFruit(model, image, scale);
        [X, Y] = bboxToPatchVertices(CC.BoundingBox);
        
        tracker.track(CC, image);
        
        if isempty(imhandles{1})
            imhandles{1} = imshow(image, 'Parent', handles(1));
        else
            set(imhandles{1}, 'cdata', image);
        end
        set(handles(1), 'YDir', 'normal');
        hold on;
        
        if isempty(patchhandle)
            patchhandle = patch(X, Y, 'r', 'Parent', handles(1), ...
                  'EdgeColor', 'r', 'FaceAlpha', '0.1');
        else
            set(patchhandle,'xdata',X,'ydata',Y);
        end
        
        % mask
        if isempty(imhandles{2})
            imhandles{2} = imshow(CC.image, 'Parent', handles(2));
        else
            set(imhandles{2}, 'cdata', CC.image);
        end
        set(handles(2), 'YDir', 'normal');
        fprintf('Processed image %i\n', count);
        count = count+1;
        drawnow;
    end
end
end
