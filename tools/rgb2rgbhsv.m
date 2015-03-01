function [ nimg ] = rgb2rgbhsv( image )
%RGB2RGBHSV Create image with 6 channels, 3 rgb & 3 hsv.
hsv = rgb2hsv(image);
nimg = cat(3,image,hsv);
end
