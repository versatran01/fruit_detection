%% init.m
clear;
close all;
home;

% Path for raw images
DATASET_PATH = getenv('BOOTH_DATASET_PATH');

% path for generated observation dataset
OBSERVATION_PATH = getenv('BOOTH_OBSERVATION_PATH');
OBSERVATION_NAME = 'observations_28-Feb-2015.mat';
LOAD_OBSERVATIONS = true;
NUM_OBSERVATIONS = [];

addpath('./descriptors');
addpath('./detection');
addpath('./kmeans');
addpath('./labeling');
addpath('./mex');
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
else
    addpath('./vendor/matlab_rosbag-mac64/');
end

if LOAD_OBSERVATIONS
    fullpath = sprintf('%s/%s',OBSERVATION_PATH,OBSERVATION_NAME);
    if exist(fullpath,'file')
        obs = initObservations(OBSERVATION_PATH, OBSERVATION_NAME,...
          NUM_OBSERVATIONS, 0.8);
    end
end

% load descriptors
load('descriptors/kmeans.mat');

% Re-seed random
rng('shuffle', 'twister');

