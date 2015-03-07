function matlab_image = rosImageToMatlabImage(ros_image_msg)

b = ros_image_msg.data(1:3:end);
g = ros_image_msg.data(2:3:end);
r = ros_image_msg.data(3:3:end);
b = reshape(b, ros_image_msg.width, ros_image_msg.height);
g = reshape(g, ros_image_msg.width, ros_image_msg.height);
r = reshape(r, ros_image_msg.width, ros_image_msg.height);
matlab_image = cat(3, r, g, b);

end