function [ nimg ] = rgb2rgbhsvlab( image )
%RGB2RGBHSV Create image with 9 channels, 3 rgb & 3 hsv & 3 lab.
hsv = rgb2hsv(image);
lab = rgb2lab(image);
nimg = cat(3,image,hsv,lab);
end
