function image_out = rgb2fullcs(image_in)
%RGB2FULLCS Create full color-space from RGB input.
image_rgb = im2double(image_in);
image_hsv = rgb2hsv(image_rgb);
image_lab = rgb2lab(image_rgb);
image_ycbcr = im2double(rgb2ycbcr(image_in));
image_out = cat(3, image_rgb, image_hsv, image_lab, image_ycbcr);
end
