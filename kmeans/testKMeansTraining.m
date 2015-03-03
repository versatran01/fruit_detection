%% trainKMeans.m
% Train feature descriptors using k-means.

SCENES_PATH = '/Volumes/External/Datasets/nirscene1';
images = loadImages(SCENES_PATH,'[0-9]+_rgb.tiff', true);

%% Sample patches
NTRAIN = 400000;
NODES = 144;

patches = samplePatchesFromSet(images, 8, NTRAIN,...
        'mono', false, 'scale', 1);
patches = {patches};

%% Train
descriptors = trainKMeans(patches, NODES);

%% Display results
W1 = descriptors{1}.weights;
displayPatches(W1, true);
