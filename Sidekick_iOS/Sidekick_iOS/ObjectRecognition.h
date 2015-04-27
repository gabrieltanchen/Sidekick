//
//  ObjectRecognition.h
//  Sidekick_iOS
//
//  Created by Gabriel Tan-Chen on 2015-02-23.
//  Copyright (c) 2015 Gabriel Tan-Chen. All rights reserved.
//

#ifndef __Sidekick_iOS__ObjectRecognition__
#define __Sidekick_iOS__ObjectRecognition__

#include <stdio.h>

#endif /* defined(__Sidekick_iOS__ObjectRecognition__) */

#import <opencv2/objdetect/objdetect.hpp>
#include <opencv2/highgui/highgui.hpp>
#include <opencv2/imgproc/imgproc.hpp>

cv::Mat detectAndDisplay(cv::Mat frame, cv::CascadeClassifier face_cascade, cv::CascadeClassifier eyes_cascade);
cv::Mat detectRedObject(cv::Mat frame, int lowH, int highH, int lowS, int highS, int lowV, int highV, int *dist, int *dir);