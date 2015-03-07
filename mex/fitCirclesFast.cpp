//  fitCirclesFast.cpp

extern "C" {
# include "mex.h"
# include "stdint.h"
# include "string.h"
}

#include <vector>
#include <cmath>
#include <random>
#include <chrono>

#include <Eigen/Dense>

using namespace Eigen;

bool isScalar(const mxArray * v) {
  return mxGetM(v)==1 && mxGetN(v)==1;
}

static int seedTime() {
  using std::chrono::system_clock;
  return static_cast<int>(system_clock::now().time_since_epoch().count());
}

bool leastSquaresCircle(const std::vector<Vector2d>& points, Vector3d& x) {
  const std::size_t N = points.size();
  if (N < 3) {
    throw std::invalid_argument("must have 3 or more points");
  }
  
  Matrix<double, Dynamic, 3> A(N,3);
  Matrix<double, Dynamic, 1> b(N,1);
  
  for (std::size_t i=0; i < N; i++) {
    const double& x = points[i][0];
    const double& y = points[i][1];
    A(i,0) = 2*x;
    A(i,1) = 2*y;
    A(i,2) = 1;
    b(i,0) = x*x + y*y;
  }
  
  Matrix3d AtA = A.transpose() * A;
  Matrix3d AtAinv;
  bool invertible;
  AtA.computeInverseWithCheck(AtAinv, invertible);
  if (!invertible) {
    //  bad combination of points, no solution
    return false;
  }
  //  otherwise solve for x
  x = AtAinv * A.transpose() * b;
  //  calculate radius
  x[2] = std::sqrt(x[2] + x[0]*x[0] + x[1]*x[1]);
  return true;
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  try {
    //  check inputs
    if(nrhs != 6) {
      throw std::invalid_argument("Six inputs required.");
    }
    else if (nlhs != 1) {
      throw std::invalid_argument("One output required.");
    }
    
    for (int i=0; i < nrhs; i++){
      if (!mxIsDouble(prhs[i])) {
        throw std::invalid_argument("All arguments must be doubles");
      }
      if (i > 0) {
        if (!isScalar(prhs[i])) {
          throw std::invalid_argument("Parameters must be scalars");
        }
      }
    }
    
    const mxArray * pointsIn = prhs[0];
    const int nIters = mxGetScalar(prhs[1]);          //  max # iterations
    const double inlierThresh = mxGetScalar(prhs[2]); //  threshold for inlier
    const double inlierFrac = mxGetScalar(prhs[3]);   //  min frac of inliers
    const int earlyExit = mxGetScalar(prhs[4]);       //  # of circles for early exit
    const double mergeDist = mxGetScalar(prhs[5]);    //  merge threshold for circle
        
    if (nIters <= 0) {
      throw std::invalid_argument("niters must be > 0");
    }
    if (inlierFrac <= 0 || inlierFrac >= 1) {
      throw std::invalid_argument("inlierFract must be in (0,1)");
    }
    
    const mwSize M = mxGetM(pointsIn);
    const mwSize N = mxGetN(pointsIn);
    if (N != 2) {
      throw std::invalid_argument("points must be Mx2");
    }
    if (M < 3) {
      throw std::invalid_argument("M must be >= 3");
    }
    
    const double * data = static_cast<double*>(mxGetData(pointsIn));
    
    //  initialize random sampler
    std::vector<int> pool(M);
    std::iota(pool.begin(), pool.end(), 0);
    std::default_random_engine generator(seedTime());
    std::uniform_int_distribution<int> distribution;
    
    std::vector<Vector3d> circles;  //  possible output circles
    std::vector<int> counts;        //  number of inliers for each circle
    std::size_t fits=0;
    
    for (int iter=0; iter < nIters; iter++) {
      //  select 3 points without replacement
      int pmax = static_cast<int>(M);
      int indices[3];
      for (int i=0; i < 3; i++) {
        //  use fischer-yates shuffle for sampling
        const int index = distribution(generator) % pmax;
        //  take index from the pool
        indices[i] = pool[index];
        //  move this index to the end so we can't sample it again
        std::swap(pool[index], pool[pmax-1]);
        pmax--;
      }
      
      //  pull out the points (column major mapping here)
      std::vector<Vector2d> points(3);
      for (int i=0; i < 3; i++) {
        const int index = indices[i];
        const double& x = data[0*M + index];
        const double& y = data[1*M + index];
        points[i] = Vector2d(x,y);
      }
      
      //  now fit a circle
      Vector3d circle;
      if ( leastSquaresCircle(points, circle) ) {
        const double& cx = circle[0];
        const double& cy = circle[1];
        const double& r = circle[2];
        //  calculate inliers
        int inliers=0;
        for (std::size_t i=0; i < M; i++) {
          const double& x = data[0*M + i];
          const double& y = data[1*M + i];
          //  how badly does this point fit the circle?
          const double err = (x-cx)*(x-cx) + (y-cy)*(y-cy) - r*r;
          const double err2 = err*err;
          //  use squared error when comparing to threshold
          if (err2 < inlierThresh*inlierThresh) {
            inliers++;
          }
        }
        
        if (inliers > inlierFrac*M) {
          //  enough inliers, this is a valid circle
          fits++;
          
          bool merged = false;
          for (std::size_t i=0; i < circles.size(); i++) {
            const double dist = (circles[i] - circle).norm();
            if (dist < mergeDist) {
              //  should be merged
              counts[i] += inliers;
              merged = true;
              break;
            }
          }
          if (!merged) {
            //  solution is not similar, do not merge
            circles.push_back(circle);
            counts.push_back(inliers);
          }
        }
        
        if (fits >= earlyExit) {
          //  reached early exit condition
          break;
        }
      }
    }
    
    //  convert outputs to MATLAB format
    const std::size_t K = circles.size();
    mxArray * out = mxCreateNumericArray(0,0,mxDOUBLE_CLASS, mxREAL);
    double * outData = static_cast<double*> (mxMalloc(K*4*sizeof(double)));
    mxSetData(out, outData);
    mxSetM(out, K);
    mxSetN(out, 4);
    plhs[0] = out;
    //  copy data out
    for (std::size_t i=0; i < K; i++) {
      outData[0*K + i] = circles[i][0];
      outData[1*K + i] = circles[i][1];
      outData[2*K + i] = circles[i][2];
      outData[3*K + i] = counts[i];
    }
    //  done!
  } catch (std::exception& e) {
    plhs[0] = mxCreateNumericArray(0,0,mxDOUBLE_CLASS, mxREAL);
    mexErrMsgIdAndTxt("fitCircles:exception",
                      e.what());
  }
}
