//
//  ObjectRecognition.cpp
//  Sidekick_iOS
//
//  Created by Gabriel Tan-Chen on 2015-02-23.
//  Copyright (c) 2015 Gabriel Tan-Chen. All rights reserved.
//

#include "ObjectRecognition.h"

cv::CascadeClassifier face_cascade;
cv::CascadeClassifier eyes_cascade;
cv::string window_name = "Capture - Face detection";

struct Point {
    int x;
    int y;
};
struct redObject {
    int minx;
    int miny;
    int maxx;
    int maxy;
    Point *points[15000];
    int numPoints;
};

cv::Mat detectAndDisplay(cv::Mat frame, cv::CascadeClassifier face_cascade, cv::CascadeClassifier eyes_cascade) {
    
    std::vector<cv::Rect> faces;
    cv::Mat frame_gray;
    
    cv::cvtColor(frame, frame_gray, CV_BGR2GRAY);
    cv::equalizeHist(frame_gray, frame_gray);
    
    return frame_gray;
    
    // Detect faces
    /*face_cascade.detectMultiScale(frame_gray, faces, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
    
    for (size_t i = 0; i < faces.size(); i++) {
        cv::Point center(faces[i].x + faces[i].width*0.5, faces[i].y + faces[i].height*0.5);
        cv::ellipse(frame, center, cv::Size(faces[i].width*0.5, faces[i].height*0.5), 0, 0, 360, cv::Scalar(255, 0, 255), 4, 8, 0);
        
        cv::Mat faceROI = frame_gray(faces[i]);
        std::vector<cv::Rect> eyes;
        
        // In each face, detect eyes
        eyes_cascade.detectMultiScale(faceROI, eyes, 1.1, 2, 0|CV_HAAR_SCALE_IMAGE, cv::Size(30, 30));
        
        for (size_t j = 0; j < eyes.size(); j++) {
            cv::Point center(faces[i].x + eyes[j].x + eyes[j].width*0.5, faces[i].y + eyes[j].y + eyes[j].height*0.5);
            int radius = cvRound((eyes[j].width + eyes[j].height)*0.25);
            cv::circle(frame, center, radius, cv::Scalar(255, 0, 0), 4, 8, 0);
        }
    }
    
    return frame;*/
}

void addObject(redObject **objects, int *numObjects, size_t x, size_t y) {
    if (*numObjects < 10) {
        (*objects[*numObjects]).minx = x;
        (*objects[*numObjects]).miny = y;
        (*objects[*numObjects]).maxx = x;
        (*objects[*numObjects]).maxy = y;
        (*(*objects[*numObjects]).points)[0].x = x;
        (*(*objects[*numObjects]).points)[0].y = y;
        (*objects[*numObjects]).numPoints = 1;
        *numObjects += 1;
    }
}

int getObjectIndex(redObject **objects, int numObjects, size_t x, size_t y) {
    
    for (int i=0; i<numObjects; i++) {
        int numPoints = (*objects[i]).numPoints;
        for (int p=0; p<numPoints; p++) {
            if ((*(*objects[i]).points[p]).x == x && (*(*objects[i]).points[p]).y == y) {
                return i;
            }
        }
    }
    
    return -1;
}

void addPointToObject(redObject **objects, int objectIndex, size_t x, size_t y) {
    int ind = (*objects[objectIndex]).numPoints;
    (*(*objects[objectIndex]).points)[ind].x = x;
    (*(*objects[objectIndex]).points)[ind].y = y;
    (*objects[objectIndex]).numPoints += 1;
}

/*void addPointToObject(redObject *objects, int objectIndex, size_t x, size_t y) {
    Point *points = new Point[objects[objectIndex].numPoints+1];
    for (int i=0; i<objects[objectIndex].numPoints; i++) {
        points[i] = (*objects[objectIndex].points)[i];
    }
    objects[objectIndex].numPoints++;
    points[objects[objectIndex].numPoints].x = x;
    points[objects[objectIndex].numPoints].y = y;
    delete [] (*objects[objectIndex].points);
    objects[objectIndex].points = &points;
    if (x < objects[objectIndex].minx) {
        objects[objectIndex].minx = x;
    }
    if (y < objects[objectIndex].miny) {
        objects[objectIndex].miny = y;
    }
    if (x > objects[objectIndex].maxx) {
        objects[objectIndex].maxx = x;
    }
    if (y > objects[objectIndex].maxy) {
        objects[objectIndex].maxy = y;
    }
}

redObject* combineObjects(redObject *objects, int *numObjects, int object1, int object2) {
    redObject *r = new redObject[*numObjects-1];
    for (int i=0; i<*numObjects; i++) {
        if (i != object2 && i < object2) {
            r[i] = objects[i];
        } else if (i != object2 && i > object2) {
            r[i-1] = objects[i];
        }
    }
    
    for (int p=0; p<objects[object2].numPoints; p++) {
        if (object1 < object2) {
            addPointToObject(r, object1, (*objects[object2].points)[p].x, (*objects[object2].points)[p].y);
        } else {
            addPointToObject(r, object1-1, (*objects[object2].points)[p].x, (*objects[object2].points)[p].y);
        }
    }
    
    *numObjects -= 1;
    
    return r;
}*/

int distance(int x1, int y1, int x2, int y2) {
    return int(sqrt((x2-x1)^2 + (y2-y1)^2));
}

cv::Mat detectRedObject(cv::Mat frame, int lowH, int highH, int lowS, int highS, int lowV, int highV, int *dist, int *dir) {
    
    cv::Mat imgGray, imgThresholded;
    
    cv::cvtColor(frame, imgGray, cv::COLOR_BGR2HSV);
    cv::inRange(imgGray, cv::Scalar(lowH, lowS, lowV), cv::Scalar(highH, highS, highV), imgThresholded);
    
    //cv::GaussianBlur(imgThresholded, imgThresholded, cv::Size(9, 9), 2, 2);
    
    // morphological opening (remove small objects from the foreground)
    cv::erode(imgThresholded, imgThresholded, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)));
    cv::dilate(imgThresholded, imgThresholded, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)));
    
    // morphological closing (fill small holes in the foreground)
    cv::dilate(imgThresholded, imgThresholded, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)));
    cv::erode(imgThresholded, imgThresholded, cv::getStructuringElement(cv::MORPH_ELLIPSE, cv::Size(5, 5)));
    
    // Find the largest red object in the image.
    /*cv::vector<cv::vector<cv::Point>> contours; // Vector for storing contour
    cv::vector<cv::Vec4i> hierarchy;
    
    int ind = 0;
    cv::Rect bound;
    cv::Mat imgcon;
    imgThresholded.copyTo(imgcon);
    cv::findContours(imgcon, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    //cv::findContours(imgcon, contours, hierarchy, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
    for (int i=0; i<contours.size(); i++) {
        double a = cv::contourArea(contours[i]);
        if (a > ind) {
            ind = i;
            bound = cv::boundingRect(contours[i]);
        }
    }
    cv::rectangle(imgThresholded, bound, cv::Scalar(125, 125, 125));*/
    
    
    /*cv::vector<cv::Vec3f> circles;
    cv::HoughCircles(imgThresholded, circles, CV_HOUGH_GRADIENT, 1.2, imgThresholded.rows/4, 200, 20, 10, 0);
    if (circles.size() > 0) {
        cv::Point center(cvRound(circles[0][0]), cvRound(circles[0][1]));
        int radius = cvRound(circles[0][2]);
        // circle centre
        cv::circle(imgThresholded, center, 3, cv::Scalar(125, 125, 125), -1, 8, 0);
        // circle outline
        cv::circle(imgThresholded, center, radius, cv::Scalar(125, 125, 125), 3, 8, 0);
    }
    for (size_t i = 0; i < circles.size(); i++) {
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        int radius = cvRound(circles[i][2]);
        // circle centre
        cv::circle(imgThresholded, center, 3, cv::Scalar(125, 125, 125), -1, 8, 0);
        // circle outline
        cv::circle(imgThresholded, center, radius, cv::Scalar(125, 125, 125), 3, 8, 0);
    }*/
    
    /*cv::vector<cv::Vec3f> circles;
    cv::HoughCircles(imgThresholded, circles, CV_HOUGH_GRADIENT, 1.2, imgThresholded.rows/16, 200, 20, 10, 0);
    
    for (size_t i = 0; i < circles.size(); i++) {
        cv::Point center(cvRound(circles[i][0]), cvRound(circles[i][1]));
        int radius = cvRound(circles[i][2]);
        // circle centre
        cv::circle(frame, center, 3, cv::Scalar(0, 0, 255), -1, 8, 0);
        // circle outline
        cv::circle(frame, center, radius, cv::Scalar(0, 255, 0), 3, 8, 0);
    }
    
    cv::transpose(frame, frame);
    
    return frame;*/
    
    /*cv::Mat imgHSV;
    cv::cvtColor(frame, imgHSV, cv::COLOR_BGR2HSV);
    cv::Mat imgThresholded;
    
    cv::inRange(imgHSV, cv::Scalar(lowH, lowS, lowV), cv::Scalar(highH, highS, highV), imgThresholded); // Threshold the image
    
    
    cv::vector<cv::Vec3f> circles;
    cv::HoughCircles(imgThresholded, circles, CV_HOUGH_GRADIENT, 1, imgThresholded.rows/16, 200, 15, 0, 0);
    
    if (circles.size() > 0) {
        cv::Point center(cvRound(circles[0][0]), cvRound(circles[0][1]));
        int radius = cvRound(circles[0][2]);
        // circle centre
        cv::circle(imgThresholded, center, 3, cv::Scalar(125, 125, 125), -1, 8, 0);
        // circle outline
        cv::circle(imgThresholded, center, radius, cv::Scalar(125, 125, 125), 3, 8, 0);
        printf("circle found");
    }*/
    
    int rows = imgThresholded.rows;
    int cols = imgThresholded.cols;
    
    int xMin = 255;
    int xMax = 0;
    int yMin = 255;
    int yMax = 0;
    
    for (size_t i = 0; i < rows; i++) {
        for (size_t j = 0; j < cols; j++) {
            if (imgThresholded.at<uchar>(i, j) == 255) {
                if (j < xMin) {
                    xMin = j;
                }
                if (j > xMax) {
                    xMax = j;
                }
                if (i < yMin) {
                    yMin = i;
                }
                if (i > yMax) {
                    yMax = i;
                }
            }
        }
    }
    
    cv::rectangle(imgThresholded, cv::Point(xMin, yMax), cv::Point(xMax, yMin), cv::Scalar(255, 255, 255));
    
    //*frame = imgThresholded;
    
    *dist = sqrt((xMax - xMin)*(xMax - xMin) + (yMax - yMin)*(yMax - yMin));
    
    int centre = imgThresholded.rows/2;
    if ((((yMax - yMin)/2)+yMin) - centre > 25) {
        *dir = 1;
    } else if ((((yMax - yMin)/2) + yMin) - centre < -25) {
        *dir = 2;
    } else {
        *dir = 0;
    }
    
    cv::transpose(imgThresholded, imgThresholded);
    
    return imgThresholded;
}