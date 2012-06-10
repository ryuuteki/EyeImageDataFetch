//
//  ImageTransfer.h
//  OpenCV_Test2
//
//  Created by  on 12/03/16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//#import "opencv/cv.h"
//#import "opencv2/imgproc/imgproc_c.h"
//#import "opencv2/objdetect/objdetect.hpp"
#import <Foundation/Foundation.h>
#import "Image.h"
#import "UIImageSimpleImageProcessing.h"

@interface ImageTransfer : NSObject

//+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image; 
//+ (UIImage *)CreateUIImageFromIplImage:(IplImage *)image;
//+ (UIImage *)TransferToGrayScaleImage:(UIImage *)image;
//+ (UIImage *)TransferToEqualizedImage:(UIImage *)image;
+ (UIImage *)convertImageToGrayScale:(UIImage *)image;
+ (UIImage *)convertImageToHistoEqual:(UIImage *)image;
+ (UIImage *)downScaleImage:(UIImage *)image toSize:(CGSize)newSize;
+ (void)convertImageToPixelValueArray: (UIImage *)image;

@end