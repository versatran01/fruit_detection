#include "mex.h"
#include <iostream>
#include <stdio.h>
#include <string.h>
#include <sys/time.h>
#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>

// [ pts ] = goodfeaturestograck( img, max_pts, quality_level, min_dist);
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]) {
  if (nrhs < 1)
    mexErrMsgTxt("Not enough input arguments");
  if (!(mxIsUint8(prhs[0]) || mxIsInt8(prhs[0])))
    mexErrMsgTxt("Image must be of type uint8 or int8");

  // Get parameters
  double min_dist = mxGetScalar(prhs[3]);
  double quality_level = mxGetScalar(prhs[2]);
  int max_pts = (int) mxGetScalar(prhs[1]);

  //mexPrintf("max_pts: %d, quality_level: %f, min_dist: %f",
  //max_pts, quality_level, min_dist);

  // Get image
  char *image_buf = (char *) mxGetData(prhs[0]);
  int height = mxGetM(prhs[0]);
  int width  = mxGetN(prhs[0]);
  cv::Mat image = cv::Mat::zeros(cv::Size(height, width), CV_8U);
  memcpy(image.data, image_buf, width * height);
  cv::transpose(image, image);

  // Detect features
  std::vector<cv::Point2f> feat;
  cv::goodFeaturesToTrack(image, feat, max_pts, quality_level, min_dist);

  // Output
  int N = feat.size();
  plhs[0] = mxCreateDoubleMatrix(2, N, mxREAL);
  double *ptr = mxGetPr(plhs[0]);
  for (unsigned int k = 0; k < N; k++) {
    ptr[2 * k]   = feat[k].x;
    ptr[2 * k + 1] = feat[k].y;
  }
  return;
}

