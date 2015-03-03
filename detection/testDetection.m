%% testDetection.m
close all;

detector = @(image)detectFruit(model, image);
tester = DetectionTester(dataset, detector);

while tester.hasNext()
    tester.processNext();
    pause;
end
