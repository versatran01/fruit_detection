%% init.m
clear;
close all;
home;

DATASET_PATH = '/Volumes/External/Datasets/booth_combined';

addpath('./descriptors');
addpath('./kmeans');
addpath('./labeling');
addpath('./scripts');
addpath('./tools');
addpath('./train');
addpath('./vendor/fkmeans');

% Re-seed random
rng('shuffle', 'twister');

