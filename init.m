%% init.m
clear;
close all;
home;

% Path for raw images
DATASET_PATH = getenv('BOOTH_DATASET_PATH');

% path for generated observation dataset
OBSERVATION_PATH = getenv('BOOTH_OBSERVATION_PATH');
OBSERVATION_NAME = 'observations_24-Feb-2015.mat';

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./predict');
addpath('./scripts');
addpath('./tools');
addpath('./train');
addpath('./vendor/fkmeans');
addpath('./vendor/liblinear/matlab')
addpath('./vendor/libsvm/matlab');

obs = initObservations(OBSERVATION_PATH, OBSERVATION_NAME, 5000, 0.8);

% Re-seed random
rng('shuffle', 'twister');

