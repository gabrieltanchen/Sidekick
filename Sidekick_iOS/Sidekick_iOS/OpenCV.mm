//
//  OpenCV.m
//  Sidekick_iOS
//
//  Created by Gabriel Tan-Chen on 2015-02-22.
//  Copyright (c) 2015 Gabriel Tan-Chen. All rights reserved.
//

#import "OpenCV.h"

#import <opencv2/opencv.hpp>
#import <opencv2/highgui/ios.h>
#import "ObjectRecognition.h"

@implementation OpenCVHandlr


- (UIImage *) detectAndDisplay:(UIImage *)frame
                      withLowH:(int)lowH
                     withHighH:(int)highH
                      withLowS:(int)lowS
                     withHighS:(int)highS
                      withLowV:(int)lowV
                     withHighV:(int)highV
                 toGetDistance:(int *)dist
                  andDirection:(int *)dir {
    
    cv::Mat cvmatframe = cv::Mat();
    [self cvMat:&cvmatframe fromUIImage:frame];

    /*NSString *face_cascade_path = [[NSBundle mainBundle] pathForResource:@"haarcascade_frontalface_alt" ofType:@"xml"];
    const char *face_cascade_p = [face_cascade_path cStringUsingEncoding:NSASCIIStringEncoding];
    NSString *eyes_cascade_path = [[NSBundle mainBundle] pathForResource:@"haarcascade_eye_tree_eyeglasses" ofType:@"xml"];
    const char *eyes_cascade_p = [eyes_cascade_path cStringUsingEncoding:NSASCIIStringEncoding];
    
    cv::CascadeClassifier face_cascade;
    if (!face_cascade.load(face_cascade_p)) {
        printf("Error loading face cascade");
        return frame;
    }
    cv::CascadeClassifier eyes_cascade;
    if (!eyes_cascade.load(eyes_cascade_p)) {
        printf("Error loading eyes cascade");
        return frame;
    }*/
    
    cv::Mat r = detectRedObject(cvmatframe, lowH, highH, lowS, highS, lowV, highV, dist, dir);
    //cv::Mat r = detectAndDisplay(cvmatframe, face_cascade, eyes_cascade);
    //UIImage *ret;
    UIImage *ret = [self UIImageFromCVMat:r];
    
    return ret;
    //frame = test;
    //return ret;
}

- (void) cvMat:(cv::Mat *) mat fromUIImage:(UIImage *)image {
    CGColorSpaceRef colourSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width * image.scale;
    CGFloat rows = image.size.height * image.scale;
    
    mat->create(rows, cols, CV_8UC4);
    //cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (colour channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(mat->data,                 // Pointer to data
                                                    mat->cols,                       // Width of bitmap
                                                    mat->rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    mat->step[0],              // Bytes per row
                                                    colourSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
}

- (UIImage *) UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colourSpace;
    
    if (cvMat.elemSize() == 1) {
        colourSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colourSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,
                                        cvMat.rows,
                                        8,
                                        8 * cvMat.elemSize(),
                                        cvMat.step[0],
                                        colourSpace,
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef scale:1.0 orientation:UIImageOrientationUp];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colourSpace);
    
    return finalImage;
}

@end
