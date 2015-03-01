function image_out = rgb2fullcs(image_in)

image_rgb = im2double(image_in);
image_hsv = rgb2hsv(image_in);
image_ycbcr = rgb2ycbcr(image_in);

image_out = cat(3, image_rgb, image_hsv, image_ycbcr);

end

