setenv('LD_LIBRARY_PATH', '/usr/lib/x86_64-linux-gnu')
mex CFLAGS="\$CFLAGS -Wall -Werror -O3 -std=c99" -largeArrayDims fastig.cpp
mex CFLAGS="\$CFLAGS -Wall -Werror -O3 -std=c99" ...
    CXXFLAGS="\$CXXFLAGS -std=c++11 -I/usr/local/include/eigen3 -fPIC" ...
    -largeArrayDims fitCirclesFast.cpp

%% Compile gftt

if ismac()
    CV_INCLUDE_PATH = '/usr/local/include';
    CV_LIBRARY_PATH = '/usr/local/lib';
else
    CV_INCLUDE_PATH = '/usr/include';
    CV_LIBRARY_PATH = '/usr/lib';
end

mex('-v','-largeArrayDims','goodfeaturestotrack.cpp', ...
   	['-I' CV_INCLUDE_PATH], ['-L' CV_LIBRARY_PATH], ['-l' 'opencv_core'],...
    ['-l' 'opencv_imgproc'], ['-l' 'opencv_calib3d']);

mex('-v','-largeArrayDims','findFundamentalMat.cpp', ...
   	['-I' CV_INCLUDE_PATH], ['-L' CV_LIBRARY_PATH], ['-l' 'opencv_core'],...
    ['-l' 'opencv_imgproc'], ['-l' 'opencv_calib3d']);
