//
//  ImageTransfer.m
//  OpenCV_Test2
//
//  Created by  on 12/03/16.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ImageTransfer.h"

@implementation ImageTransfer

+ (UIImage *)downScaleImage:(UIImage *)image toSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}


// NOTE 戻り値は利用後cvReleaseImage()で解放してください
+ (IplImage *)CreateIplImageFromUIImage:(UIImage *)image {
    // CGImageをUIImageから取得
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // 一時的なIplImageを作成
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // CGContextを一時的なIplImageから作成
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // CGImageをCGContextに描画
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // 最終的なIplImageを作成
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

// NOTE IplImageは事前にRGBモードにしておいてください。
+ (UIImage *)CreateUIImageFromIplImage:(IplImage *)image {
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // CGImageのためのバッファを確保
    NSData *data =
    [NSData dataWithBytes:image->imageData length:image->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef) data);
    // IplImageのデータからCGImageを作成
    CGImageRef imageRef = CGImageCreate(
                                        image->width, image->height,
                                        image->depth, image->depth * image->nChannels, image->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // UIImageをCGImageから取得
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
}
/*
+ (IplImage *)TransferToGrayScaleImage:(UIImage *)image {
// Either convert the image to greyscale, or use the existing greyscale image.
	IplImage *imageSrc = [self CreateIplImageFromUIImage:image];
	IplImage *imageGray;
	if (imageSrc) {
		NSLog(@"iamgesrc not null");
		if (imageSrc->nChannels!=3) {
			NSLog(@"nChannel not 3 !");
		}
	}
	if (imageSrc->nChannels == 3) {
		imageGray = cvCreateImage( cvGetSize(imageSrc), IPL_DEPTH_8U, 1 );
		// Convert from RGB (actually it is BGR) to Greyscale.
		cvCvtColor( imageSrc, imageGray, CV_BGR2GRAY );
	}
	else {
		// Just use the input image, since it is already Greyscale.
		imageGray = imageSrc;
	}
	return imageGray;
}
*/
+ (UIImage *)convertImageToGrayScale:(UIImage *)image
{
	// Create image rectangle with current image width/height
	CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
	
	// Grayscale color space
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
	
	// Create bitmap content with current image size and grayscale colorspace
	CGContextRef context = CGBitmapContextCreate(nil, image.size.width, image.size.height, 8, 0, colorSpace, kCGImageAlphaNone);
	
	// Draw image into current context, with specified rectangle
	// using previously defined context (with grayscale colorspace)
	CGContextDrawImage(context, imageRect, [image CGImage]);
	
	// Create bitmap image info from pixel data in current context
	CGImageRef imageRef = CGBitmapContextCreateImage(context);
	
	// Create a new UIImage object  
	UIImage *newImage = [UIImage imageWithCGImage:imageRef];
	
	// Release colorspace, context and bitmap information
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(context);
	CFRelease(imageRef);
	
	// Return the new grayscale image
	return newImage;
}

+ (UIImage *)convertImageToHistoEqual:(UIImage *)image {
	// CGImageをUIImageから取得
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceGray();
    // 一時的なIplImageを作成
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 1
                                       );

	
	// CGContextを一時的なIplImageから作成
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // CGImageをCGContextに描画
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    
    // 最終的なIplImageを作成
    IplImage *processedIplImage = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 1);
    cvCvtColor(iplimage, processedIplImage, CV_BGR2GRAY);
    cvReleaseImage(&iplimage);
    
	//Histogram Equalization
	cvEqualizeHist(processedIplImage, processedIplImage);
	
	
    NSData *data =
    [NSData dataWithBytes:processedIplImage->imageData length:processedIplImage->imageSize];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef) data);
    // IplImageのデータからCGImageを作成
    imageRef = CGImageCreate(
                                        processedIplImage->width, processedIplImage->height,
                                        processedIplImage->depth, processedIplImage->depth * processedIplImage->nChannels, processedIplImage->widthStep,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    // UIImageをCGImageから取得
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    return ret;
	
}

+ (void)convertImageToPixelValueArray: (UIImage *)image {

	//Downscaled Image
	CGSize downScaledImageSize = CGSizeMake(25, 15);
	image = [self downScaleImage:image toSize:downScaledImageSize];
	//Grayscaled Image
	image = [self convertImageToGrayScale:image];
	//Histogram Equalized Image
	image = [image imageByHistogramEqualisation];

	//Get the indesity matrix of the processed image
	NSData* pixelData = (NSData*) CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
	unsigned char* pixelBytes = (unsigned char *)[pixelData bytes];
	int width = (int)downScaledImageSize.width;
	int counter = width;
	//NSLog(@"%d",[pixelData length]);
	for(int i = 0; i < [pixelData length]; i += 4) {
		printf("%d\t",pixelBytes[i+3]);
		counter --;
		if (counter == 0) {
			printf("\n");
			counter = width;
		}
	}
	
	
}



@end
