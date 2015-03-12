extern "C" {
# include "mex.h"
}

#include <stdexcept>
#include <vector>

#include <opencv2/core/core.hpp>
#include <opencv2/imgproc/imgproc.hpp>
#include <opencv2/calib3d/calib3d.hpp>

bool isScalar(const mxArray * v) {
  return mxGetM(v)==1 && mxGetN(v)==1;
}

// [ F, inliers ] = findFundamentalMat( points1, point2, threshold, confidence )
void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[]) {
  
  try {
    //  check inputs
    if(nrhs != 4) {
      throw std::invalid_argument("Four inputs required.");
    }
    for (int i=0; i < 4; i++) {
      if (!mxIsDouble(prhs[i])) {
        throw std::invalid_argument("Arguments must be double");
      }
      if (i > 1) {
        if (!isScalar(prhs[i])) {
          throw std::invalid_argument("Threshold and confidence should be scalars");
        }
      }
    }
    
    const mwSize M = mxGetM(prhs[0]);
    if (mxGetM(prhs[1]) != M || mxGetN(prhs[0]) != 2 || mxGetN(prhs[1]) != 2) {
      throw std::invalid_argument("points1 and points2 should be Mx2");
    }
    
    const double * pts0Data = static_cast<double*>(mxGetData(prhs[0]));
    const double * pts1Data = static_cast<double*>(mxGetData(prhs[1]));
    const double threshold = mxGetScalar(prhs[2]);
    const double confidence = mxGetScalar(prhs[3]);
    
    if (confidence < 0 || confidence >= 1) {
      throw std::invalid_argument("confidence should be in [0,1)");
    }
    
    //  convert to vectors
    std::vector<cv::Point2f> pts0, pts1;
    for (std::size_t i=0; i < M; i++) {
      pts0.push_back(cv::Point2f(pts0Data[0*M + i], pts0Data[1*M + i]));
      pts1.push_back(cv::Point2f(pts1Data[0*M + i], pts1Data[1*M + i]));
    }
    
    //  solve
    std::vector<unsigned char> status;
    cv::Mat F = cv::findFundamentalMat(pts0, pts1, cv::FM_RANSAC, threshold,
                                       confidence, status);
    
    //  generate outputs
    if (nlhs > 0) {
      plhs[0] = mxCreateDoubleMatrix(3,3,mxREAL);
      double * data = mxGetPr(plhs[0]);
      for (int i=0; i < 3; i++) {
        for (int j=0; j < 3; j++) {
          //  convert to column major format
          data[j*3 + i] = F.at<double>(i,j);
        }
      }
    }
    if (nlhs > 1) {
      plhs[1] = mxCreateLogicalMatrix(status.size(), 1);
      mxLogical * data = mxGetLogicals(plhs[1]);
      for (std::size_t i=0; i < status.size(); i++) {
        data[i] = status[i];
      }
    }
  }
  catch(std::exception& e) {
    mexErrMsgIdAndTxt("findFundamentalMat:exception",
                      e.what());
  }
}

