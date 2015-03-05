%% testDetection.m
close all;
home;

viz = true;

detector = @(image)detectFruit(model, image);
tester = DetectionTester(dataset, detector,viz);
tester.setCurrentImage(1);

count = 0;
while tester.hasNext()
    tester.processNext();
    count=count+1;
    if viz
        pause;
    else
        fprintf('Processed image %i of %i\n', count, dataset.size());
    end
end

%% output results
metrics = sum(tester.metrics);
tp = metrics(1);
fp = metrics(2);
fn = metrics(3);

acc = tp / (tp+fp+fn);    % accuracy
pre = tp / (tp + fp);     % precision
rec = tp / (tp + fn);     % recall

fprintf('Accuracy: %f\n', acc);
fprintf('Precision (fruit / total detections): %f\n', pre);
fprintf('Recall (fruit / possible fruit): %f\n', rec);

