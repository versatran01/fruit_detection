mex CFLAGS="\$CFLAGS -Wall -Werror -O3 -std=c99" -largeArrayDims fastig.cpp
mex CFLAGS="\$CFLAGS -Wall -Werror -O3 -std=c99" CXXFLAGS="\$CXXFLAGS -I/usr/local/include/eigen3" -largeArrayDims fitCirclesFast.cpp
