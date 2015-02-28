%% init.m
clear;
close all;
home;

% Path for raw images
DATASET_PATH = getenv('BOOTH_DATASET_PATH');

% path for generated observation dataset
OBSERVATION_PATH = getenv('BOOTH_OBSERVATION_PATH');
OBSERVATION_NAME = 'observations_27-Feb-2015.mat';
LOAD_OBSERVATIONS = true;
LOAD_DATASET = false;
NUM_OBSERVATIONS = 5000;

addpath('./descriptors');
addpath('./detection');
addpath('./kmeans');
addpath('./labeling');
addpath('./predict');
addpath('./scripts');
addpath('./tools');
addpath('./train');
addpath('./tune');
addpath('./vendor/fkmeans');
addpath('./vendor/liblinear/matlab')
addpath('./vendor/libsvm/matlab');
if ~ismac()
    addpath('./vendor/matlab_rosbag-linux64');
end

if ~isempty(DATASET_PATH) && LOAD_DATASET
    dataset = Dataset(DATASET_PATH);
end

if LOAD_OBSERVATIONS
    obs = initObservations(OBSERVATION_PATH, OBSERVATION_NAME,...
        NUM_OBSERVATIONS, 0.8);
end

% load descriptors
load('descriptors/kmeans.mat');

% Re-seed random
rng('shuffle', 'twister');

