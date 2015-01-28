%% init.m
clear;
close all;
home;
dbstop error;

DATASET_PATH = '/Users/gareth/Public/Dropbox/agriculture_state_of_art/Field Data/Selected images';

addpath('./labeling');
addpath('./tools');
addpath('./cpp');

images = loadImages(DATASET_PATH);

