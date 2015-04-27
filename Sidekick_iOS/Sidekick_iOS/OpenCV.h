//
//  OpenCV.h
//  Sidekick_iOS
//
//  Created by Gabriel Tan-Chen on 2015-02-22.
//  Copyright (c) 2015 Gabriel Tan-Chen. All rights reserved.
//

#ifndef Sidekick_iOS_OpenCV_h
#define Sidekick_iOS_OpenCV_h


#endif
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface OpenCVHandlr : NSObject

- (UIImage *) detectAndDisplay:(UIImage *)frame
                      withLowH:(int)lowH
                     withHighH:(int)highH
                      withLowS:(int)lowS
                     withHighS:(int)highS
                      withLowV:(int)lowV
                     withHighV:(int)highV
                 toGetDistance:(int *)dist
                  andDirection:(int *)dir;

@end