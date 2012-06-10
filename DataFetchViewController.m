//
//  ViewController.m
//  EyeImageDataFetch
//
//  Created by Liu Di on 6/2/12.
//  Copyright (c) 2012 Hiroshima University. All rights reserved.
//

#import "DataFetchViewController.h"

#pragma mark-

// used for KVO observation of the @"capturingStillImage" property to perform flash bulb animation
static const NSString *AVCaptureStillImageIsCapturingStillImageContext = @"AVCaptureStillImageIsCapturingStillImageContext";

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size);
static void ReleaseCVPixelBuffer(void *pixel, const void *data, size_t size) 
{	
	CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)pixel;
	CVPixelBufferUnlockBaseAddress( pixelBuffer, 0 );
	CVPixelBufferRelease( pixelBuffer );
}

static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut);
static OSStatus CreateCGImageFromCVPixelBuffer(CVPixelBufferRef pixelBuffer, CGImageRef *imageOut) 
{	
	OSStatus err = noErr;
	OSType sourcePixelFormat;
	size_t width, height, sourceRowBytes;
	void *sourceBaseAddr = NULL;
	CGBitmapInfo bitmapInfo;
	CGColorSpaceRef colorspace = NULL;
	CGDataProviderRef provider = NULL;
	CGImageRef image = NULL;
	
	sourcePixelFormat = CVPixelBufferGetPixelFormatType( pixelBuffer );
	if ( kCVPixelFormatType_32ARGB == sourcePixelFormat )
		bitmapInfo = kCGBitmapByteOrder32Big | kCGImageAlphaNoneSkipFirst;
	else if ( kCVPixelFormatType_32BGRA == sourcePixelFormat )
		bitmapInfo = kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipFirst;
	else
		return -95014; // only uncompressed pixel formats
	
	sourceRowBytes = CVPixelBufferGetBytesPerRow( pixelBuffer );
	width = CVPixelBufferGetWidth( pixelBuffer );
	height = CVPixelBufferGetHeight( pixelBuffer );
	
	CVPixelBufferLockBaseAddress( pixelBuffer, 0 );
	sourceBaseAddr = CVPixelBufferGetBaseAddress( pixelBuffer );
	
	colorspace = CGColorSpaceCreateDeviceRGB();
    
	CVPixelBufferRetain( pixelBuffer );
	provider = CGDataProviderCreateWithData( (void *)pixelBuffer, sourceBaseAddr, sourceRowBytes * height, ReleaseCVPixelBuffer);
	image = CGImageCreate(width, height, 8, 32, sourceRowBytes, colorspace, bitmapInfo, provider, NULL, true, kCGRenderingIntentDefault);
	
bail:
	if ( err && image ) {
		CGImageRelease( image );
		image = NULL;
	}
	if ( provider ) CGDataProviderRelease( provider );
	if ( colorspace ) CGColorSpaceRelease( colorspace );
	*imageOut = image;
	return err;
}

// utility used by newSquareOverlayedImageForFeatures for 
static CGContextRef CreateCGBitmapContextForSize(CGSize size);
static CGContextRef CreateCGBitmapContextForSize(CGSize size)
{
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    int             bitmapBytesPerRow;
	
    bitmapBytesPerRow = (size.width * 4);
	
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate (NULL,
									 size.width,
									 size.height,
									 8,      // bits per component
									 bitmapBytesPerRow,
									 colorSpace,
									 kCGImageAlphaPremultipliedLast);
	CGContextSetAllowsAntialiasing(context, NO);
    CGColorSpaceRelease( colorSpace );
    return context;
}

#pragma mark-

@interface UIImage (RotationMethods)
- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees;
@end

@implementation UIImage (RotationMethods)

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees 
{   
	// calculate the size of the rotated view's containing box for our drawing space
	UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0,self.size.width, self.size.height)];
	CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(degrees));
	rotatedViewBox.transform = t;
	CGSize rotatedSize = rotatedViewBox.frame.size;
	[rotatedViewBox release];
	
	// Create the bitmap context
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();
	
	// Move the origin to the middle of the image so we will rotate and scale around the center.
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);
	
	//   // Rotate the image context
	CGContextRotateCTM(bitmap, DegreesToRadians(degrees));
	
	// Now, draw the rotated/scaled image into the context
	CGContextScaleCTM(bitmap, 1.0, -1.0);
	CGContextDrawImage(bitmap, CGRectMake(-self.size.width / 2, -self.size.height / 2, self.size.width, self.size.height), [self CGImage]);
	
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
	
}

@end


@interface DataFetchViewController ()

@end

@implementation DataFetchViewController
@synthesize button1,button2,button3,button4,button5,button6;
@synthesize buttonTimer,fetchDataTimer, imageDataArray, positionInfoArray;
@synthesize _session, _imageView, capturedImage;

//Call by buttonTimer to hight light the buttons in turn every intervel
-(void)highlightButtons {
	//NSLog(@"highlightbuttons function start!");
	//Repeat times equal to the number of divided regions of the screen
	if (currentAreaNum<AreaNum) {
		currentAreaNum++;
		//Clear all the buttons, make them to white color
		[self clearButtonsColor];
		//Stop the timer for catching image data
		[self stopTimer:fetchDataTimer];
		fetchDataTimer = nil;
		
		//Hight light the 6 buttons in turn
		switch (currentAreaNum) {
			case 1:
				NSLog(@"High lighting button %d", currentAreaNum);
				button1.titleLabel.backgroundColor = [UIColor redColor];
				fetchDataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                                  target:self
                                                                selector:@selector(fetchDataTimerHandler:)
                                                                userInfo:@"1"
                                                                 repeats:YES];
				break;
			case 2:
				NSLog(@"High lighting button %d", currentAreaNum);
				button2.titleLabel.backgroundColor = [UIColor redColor];
				fetchDataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																  target:self
																selector:@selector(fetchDataTimerHandler:)
																userInfo:@"2"
																 repeats:YES];
				break;
			case 3:
				NSLog(@"buttonNum = %d", currentAreaNum);
				button3.titleLabel.backgroundColor = [UIColor redColor];
				fetchDataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																  target:self
																selector:@selector(fetchDataTimerHandler:)
																userInfo:@"3"
																 repeats:YES];
				break;
			case 4:
				NSLog(@"buttonNum = %d", currentAreaNum);
				button4.titleLabel.backgroundColor = [UIColor redColor];
				fetchDataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																  target:self
																selector:@selector(fetchDataTimerHandler:)
																userInfo:@"4"
																 repeats:YES];
				break;
			case 5:
				NSLog(@"buttonNum = %d", currentAreaNum);
				button5.titleLabel.backgroundColor = [UIColor redColor];
				fetchDataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																  target:self
																selector:@selector(fetchDataTimerHandler:)
																userInfo:@"5"
																 repeats:YES];
				break;
			case 6:
				NSLog(@"buttonNum = %d", currentAreaNum);
				button6.titleLabel.backgroundColor = [UIColor redColor];
				fetchDataTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
																  target:self
																selector:@selector(fetchDataTimerHandler:)
																userInfo:@"6"
																 repeats:YES];
				break;
			default:
				break;
		}
		
	}
	else {
		[self clearButtonsColor];
		[self stopTimer:buttonTimer];
		[self stopTimer:fetchDataTimer];
	}
	
}

-(void)clearButtonsColor {
	//NSLog(@"clear color function start");
	button1.titleLabel.backgroundColor = [UIColor whiteColor];
	button2.titleLabel.backgroundColor = [UIColor whiteColor];
	button3.titleLabel.backgroundColor = [UIColor whiteColor];
	button4.titleLabel.backgroundColor = [UIColor whiteColor];
	button5.titleLabel.backgroundColor = [UIColor whiteColor];
	button6.titleLabel.backgroundColor = [UIColor whiteColor];
	
}


-(void)buttonTimerHandler:(NSTimer *) timer {
	//int buttonNum = [[timer userInfo] intValue];
	//NSLog (@"Got the string: %@", [timer userInfo] );
	//[self clearButtonsColor];
	[self highlightButtons];
}

-(void)fetchDataTimerHandler:(NSTimer *) timer {
	//NSLog(@"fetchDataTimerHandler started!");
	int buttonNum = [[timer userInfo] intValue];
	NSLog (@"Timer handler started for Button : %d", buttonNum );
	if (_captureImage == NO) {
		//NSLog(@"Flag changed to YES!");
		//Set the captureImage flag 
		//to notify the imageCaptureOutput to prepare to capture image
		_captureImage = YES;
	}
	else {
		//NSLog(@"Flag is currently YES!");
	}
    
	//[self saveImageDataToFile:imageDataArray withPositionInfo:positionInfoArray];
    
}


- (void) stopTimer: (NSTimer *) timer
{
    if (timer) {
        [timer invalidate];
        timer = nil;
    }
	
}


-(void)saveImageDataToFile: (NSMutableArray *)image withPositionInfo: (NSMutableArray *)position {
	// get the path, like this because I didn't know any other method
	//NSString *filePath = [[NSBundle mainBundle] pathForResource:@"TrainingData" ofType:@"txt"];
	NSString *filePath=[NSTemporaryDirectory() stringByAppendingString:@"TrainingData.txt"];
	//NSLog(@"the path is: %@", filePath);
    
	// save the array
	BOOL saved=[NSKeyedArchiver archiveRootObject:positionInfoArray toFile:filePath];
	if(saved){
		NSLog(@"saved");
	}else{
		NSLog(@"Not saved");
	}
	
}

/* Former Eyedetect project
-(void)setupCaptureSession {
	NSError *error = nil;
	// Create the session. 
	_session = [[AVCaptureSession alloc] init];
	// Configure the session to produce lower resolution video frames, if your 
	// processing algorithm can cope. We'll specify medium quality for the 
	// chosen device. 
	//_session.sessionPreset = AVCaptureSessionPresetMedium;
	// Find a suitable AVCaptureDevice. 
	AVCaptureDevice *device = [self frontFacingCameraIfAvailable];
	/*[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];*/
/*
	// Create a device input with the device and add it to the session. 
	AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device
																		error:&error];
	if (!input) { 
		// Handling the error appropriately.
	} 
	[_session addInput:input];
	// Create a VideoDataOutput and add it to the session. 
	AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init]; 
	[_session addOutput:output];
	// Configure your output. 
	
	dispatch_queue_t queue = dispatch_queue_create("cameraQueue", NULL); 
	[output setSampleBufferDelegate:self queue:queue]; 
	dispatch_release(queue);
	
	_session.sessionPreset=AVCaptureSessionPresetLow;
    /*sessionPresent choose appropriate value to get desired speed*/
	/*
	// Specify the pixel format. 
	output.videoSettings = [NSDictionary dictionaryWithObject:
							[NSNumber numberWithInt:kCVPixelFormatType_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	
	// If you wish to cap the frame rate to a known value, such as 15 fps, set 
	// minFrameDuration.
	output.minFrameDuration = CMTimeMake(1, 15);
	
	// Start the session running to start the flow of data. 
	[_session startRunning];
}
*/

/*Former EyeDetect project
-(AVCaptureDevice *)frontFacingCameraIfAvailable {
	NSArray *videoDevices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]; 
	AVCaptureDevice *captureDevice = nil; 
	for (AVCaptureDevice *device in videoDevices) {
		if (device.position == AVCaptureDevicePositionFront) {
			captureDevice = device; 
			break;
		}
		if ( ! captureDevice) {
			captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo]; 
		}
	}
	return captureDevice;
}
*/

/* Former EyeDetect project
-(UIImage *) rotateImage:(UIImage*)image orientation:(UIImageOrientation) orient { 
	CGImageRef imgRef = image.CGImage; 
	CGAffineTransform transform = CGAffineTransformIdentity; 
	//UIImageOrientation orient = image.imageOrientation;
	CGFloat scaleRatio = 1; 
	CGFloat width = image.size.width; 
	CGFloat height = image.size.height; 
	CGSize imageSize = image.size; 
	CGRect bounds = CGRectMake(0, 0, width, height); 
	CGFloat boundHeight;
	switch(orient) { 
		case UIImageOrientationUp:
			transform = CGAffineTransformIdentity;
			break; 
		case UIImageOrientationUpMirrored:
			transform = CGAffineTransformMakeTranslation(imageSize.width, 0.0); 
			transform = CGAffineTransformScale(transform, -1.0, 1.0); 
			break;
		case UIImageOrientationDown:
			transform = CGAffineTransformMakeTranslation(imageSize.width, imageSize.height);
			transform = CGAffineTransformRotate(transform, M_PI);
			break; 
		case UIImageOrientationDownMirrored:
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.height); 
			transform = CGAffineTransformScale(transform, 1.0, -1.0); 
			break;
		case UIImageOrientationLeftMirrored: boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width; 
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeTranslation(imageSize.height, imageSize.height); 
			transform = CGAffineTransformScale(transform, -1.0, 1.0); 
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0); 
			break;
		case UIImageOrientationLeft: boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width; 
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeTranslation(0.0, imageSize.width); 
			transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0); 
			break;
		case UIImageOrientationRightMirrored: boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width; 
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeScale(-1.0, 1.0); 
			transform = CGAffineTransformRotate(transform, M_PI / 2.0); 
			break;
		case UIImageOrientationRight: boundHeight = bounds.size.height; 
			bounds.size.height = bounds.size.width; 
			bounds.size.width = boundHeight; 
			transform = CGAffineTransformMakeTranslation(imageSize.height, 0.0); 
			transform = CGAffineTransformRotate(transform, M_PI / 2.0); 
			break;
		default: [NSException raise:NSInternalInconsistencyException format:@"Invalid image orientation"]; 
	}
	UIGraphicsBeginImageContext(bounds.size); 
	CGContextRef context = UIGraphicsGetCurrentContext(); 
	if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft) {
		CGContextScaleCTM(context, -scaleRatio, scaleRatio);
		CGContextTranslateCTM(context, -height, 0); 
	} 
	else {
		CGContextScaleCTM(context, scaleRatio, -scaleRatio); 
		CGContextTranslateCTM(context, 0, -height);
	} 
	CGContextConcatCTM(context, transform); 
	CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef); 
	UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext(); UIGraphicsEndImageContext();
	return imageCopy;
}
*/
/*Former EyeDetect project
- (UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer {
	// Get a CMSampleBuffer's Core Video image buffer for the media data 
	CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer); 
	// Lock the base address of the pixel buffer 
	CVPixelBufferLockBaseAddress(imageBuffer, 0);
	// Get the number of bytes per row for the pixel buffer 
	void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
	// Get the number of bytes per row for the pixel buffer 
	size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
	// Get the pixel buffer width and height 
	size_t width = CVPixelBufferGetWidth(imageBuffer); 
	size_t height = CVPixelBufferGetHeight(imageBuffer);
	// Create a device-dependent RGB color space 
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	// Create a bitmap graphics context with the sample buffer data 
	CGContextRef context = CGBitmapContextCreate(baseAddress, width, height, 8,
												 bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
	
	// Create a Quartz image from the pixel data in the bitmap graphics context 
	CGImageRef quartzImage = CGBitmapContextCreateImage(context); 
	// Unlock the pixel buffer 
	CVPixelBufferUnlockBaseAddress(imageBuffer,0);
	// Free up the context and color space CGContextRelease(context); 
	CGColorSpaceRelease(colorSpace);
	// Create an image object from the Quartz image 
	UIImage *image = [UIImage imageWithCGImage:quartzImage];
	// Release the Quartz image CGImageRelease(quartzImage);
	return (image);
}
 */

/*Former EyeDetect project
- (void)captureOutput:(AVCaptureOutput *)captureOutput 
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer 
	   fromConnection:(AVCaptureConnection *)connection 
{ 
	//NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//Check the captureImage flag before capture the image
	if (_captureImage ==YES) {
		//NSLog(@"ready to capture image from camera.");
		UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
		if(_settingImage == NO) { 
			//Set the orientation of raw image captured by camera
			image = [self rotateImage:image orientation:UIImageOrientationLeftMirrored]; 
			_settingImage = YES; 
			//NSLog(@"Image been set.");
			//Create new thread to run function for handling captured image
			[NSThread detachNewThreadSelector:@selector(handleCapturedImage:) 
									 toTarget:self
								   withObject:image]; 
		}
        
	}
	//[pool drain];
}
*/

-(void)handleCapturedImage: (UIImage *)image {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSLog(@"handleCpapturedImage function started!");
	//image = [EyesCrop opencvEyesCrop:image];
	if (image) {
		_imageView.image = image;
		//[ImageTransfer convertImageToPixelValueArray:image];
		_captureImage = NO; //Comment to do captureImage always
		_settingImage = NO;
		NSLog(@"Image captured successfully!");
	} else {
		NSLog(@"Image capture Failed!");
	}
    
    
	
	[pool drain];
}

// For EyeLine project
/*
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
	if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
		if (viewRatio > apertureRatio) {
			size.width = apertureSize.height * (frameSize.height / apertureSize.width);
			size.height = frameSize.height;
		} else {
			size.width = frameSize.width;
			size.height = apertureSize.width * (frameSize.width / apertureSize.height);
		}
	}
    
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}
*/

/*EyeLine project
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap
{
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count];
	NSString *featureLayerName;
	struct CGImage *featureImage;
	if (eyeLine) {
		featureLayerName = @"EyeLineLayer";
		featureImage = [eyeLinePNG CGImage];
	}
	else {
		featureLayerName = @"FaceLayer";
		featureImage = [squarePNG CGImage];
	}
    
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] || [[layer name] isEqualToString:@"EyeLineLayer"]) {
			layer.hidden = YES;
		}
	}	
	
	if ( featuresCount == 0 ) {
		[CATransaction commit];
		return; // early bail.
	}
	
	CGSize parentFrameSize = [self.view frame].size;
	NSString *gravity = [previewLayer videoGravity];
	CGRect previewBox = [DataFetchViewController videoPreviewBoxForGravity:gravity 
														frameSize:parentFrameSize 
													 apertureSize:clap.size];
    
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        
		if ( eyeLine && ff.hasLeftEyePosition && ff.hasRightEyePosition) {
			// flip EyePosition
			CGPoint leftEyePosition = CGPointMake(ff.leftEyePosition.y, ff.leftEyePosition.x);
			CGPoint rightEyePosition = CGPointMake(ff.rightEyePosition.y, ff.rightEyePosition.x);
            
			// make rect for eyeLine
			CGFloat xAdd = (rightEyePosition.x - leftEyePosition.x) / 3.0f;
			CGFloat yAdd = xAdd / 2.0f;
			if (leftEyePosition.y>rightEyePosition.y) {
				faceRect = CGRectMake(leftEyePosition.x - xAdd, rightEyePosition.y - yAdd,
									  rightEyePosition.x - leftEyePosition.x + xAdd * 2.0f,
									  leftEyePosition.y - rightEyePosition.y + yAdd * 2.0f);
			}
			else {
				faceRect = CGRectMake(leftEyePosition.x- xAdd, leftEyePosition.y - yAdd,
									  rightEyePosition.x - leftEyePosition.x + xAdd * 2.0f,
									  rightEyePosition.y - leftEyePosition.y + yAdd * 2.0f);			
			}
		}
		else {
			// flip preview width and height
			CGFloat temp = faceRect.size.width;
			faceRect.size.width = faceRect.size.height;
			faceRect.size.height = temp;
			temp = faceRect.origin.x;
			faceRect.origin.x = faceRect.origin.y;
			faceRect.origin.y = temp;
		}
		
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:featureLayerName] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			[featureLayer setContents:(__bridge id)featureImage];
			[featureLayer setName:featureLayerName];
			[previewLayer addSublayer:featureLayer];
		}
		[featureLayer setFrame:faceRect];
	}
	
	[CATransaction commit];
}
*/
 
/*Function for eyeLine project
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
	   fromConnection:(AVCaptureConnection *)connection
{
	// got an image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(__bridge NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
    
	NSDictionary *imageOptions = nil;
	int exifOrientation;
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.  
	};
	exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
	NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false */ //originIsTopLeft == false);
    /*
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:clap];
	});
    
}
*/

- (void)setupAVCapture
{
    /* for eyeline project
	AVCaptureSession* captureSession;
	captureSession = [AVCaptureSession new];
    AVCaptureDevice *device = [self frontFacingCameraIfAvailable];
	NSError *error = nil;
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	if ([captureSession canAddInput:deviceInput]) {
		[captureSession addInput:deviceInput];
		[captureSession beginConfiguration];
		captureSession.sessionPreset = AVCaptureSessionPreset640x480;
		[captureSession commitConfiguration];
	}
	
	videoDataOutput = [AVCaptureVideoDataOutput new];
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[videoDataOutput setVideoSettings:rgbOutputSettings];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
	videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
	
    if ( [captureSession canAddOutput:videoDataOutput] )
		[captureSession addOutput:videoDataOutput];
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
	
	previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
	[previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	CALayer *rootLayer = [previewView layer];
	[rootLayer setMasksToBounds:YES];
	[previewLayer setFrame:[rootLayer bounds]];
	[rootLayer addSublayer:previewLayer];
	[captureSession startRunning];
     */
    NSError *error = nil;
	
	AVCaptureSession *session = [AVCaptureSession new];
	if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
	    [session setSessionPreset:AVCaptureSessionPreset640x480];
	else
	    [session setSessionPreset:AVCaptureSessionPresetPhoto];
	
    // Select a video device, make an input
	AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
	AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
	require( error == nil, bail );
	{
    isUsingFrontFacingCamera = NO;
    
	if ( [session canAddInput:deviceInput] )
		[session addInput:deviceInput];
	
    // Make a still image output
	stillImageOutput = [AVCaptureStillImageOutput new];
	[stillImageOutput addObserver:self forKeyPath:@"capturingStillImage" options:NSKeyValueObservingOptionNew context:nil];
	if ( [session canAddOutput:stillImageOutput] )
		[session addOutput:stillImageOutput];
	
    // Make a video data output
	videoDataOutput = [AVCaptureVideoDataOutput new];
	
    // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
	NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
									   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
	[videoDataOutput setVideoSettings:rgbOutputSettings];
	[videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked (as we process the still image)
    
    // create a serial dispatch queue used for the sample buffer delegate as well as when a still image is captured
    // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
    // see the header doc for setSampleBufferDelegate:queue: for more information
	videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
	[videoDataOutput setSampleBufferDelegate:self queue:videoDataOutputQueue];
	
    if ( [session canAddOutput:videoDataOutput] )
		[session addOutput:videoDataOutput];
	[[videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:NO];
	
	effectiveScale = 1.0;
	previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:session];
	[previewLayer setBackgroundColor:[[UIColor blackColor] CGColor]];
	[previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
	CALayer *rootLayer = [previewView layer];
	[rootLayer setMasksToBounds:YES];
	[previewLayer setFrame:[rootLayer bounds]];
	[rootLayer addSublayer:previewLayer];
	[session startRunning];
    }
bail:
	{
    [session release];
	if (error) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
		[self teardownAVCapture];
	}
    }

    
}

// use front/back camera
- (IBAction)switchCameras
{
	AVCaptureDevicePosition desiredPosition;
	if (isUsingFrontFacingCamera)
		desiredPosition = AVCaptureDevicePositionBack;
	else
		desiredPosition = AVCaptureDevicePositionFront;
	
	for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
		if ([d position] == desiredPosition) {
			[[previewLayer session] beginConfiguration];
			AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:d error:nil];
			for (AVCaptureInput *oldInput in [[previewLayer session] inputs]) {
				[[previewLayer session] removeInput:oldInput];
			}
			[[previewLayer session] addInput:input];
			[[previewLayer session] commitConfiguration];
			break;
		}
	}
	isUsingFrontFacingCamera = !isUsingFrontFacingCamera;
}

// clean up capture setup
- (void)teardownAVCapture
{
	[videoDataOutput release];
	if (videoDataOutputQueue)
		dispatch_release(videoDataOutputQueue);
	[stillImageOutput removeObserver:self forKeyPath:@"isCapturingStillImage"];
	[stillImageOutput release];
	[previewLayer removeFromSuperlayer];
	[previewLayer release];
}

// utility routing used during image capture to set up capture orientation
- (AVCaptureVideoOrientation)avOrientationForDeviceOrientation:(UIDeviceOrientation)deviceOrientation
{
	AVCaptureVideoOrientation result = deviceOrientation;
	if ( deviceOrientation == UIDeviceOrientationLandscapeLeft )
		result = AVCaptureVideoOrientationLandscapeRight;
	else if ( deviceOrientation == UIDeviceOrientationLandscapeRight )
		result = AVCaptureVideoOrientationLandscapeLeft;
	return result;
}

// utility routine to create a new image with the red square overlay with appropriate orientation
// and return the new composited image which can be saved to the camera roll
- (CGImageRef)newSquareOverlayedImageForFeatures:(NSArray *)features 
                                       inCGImage:(CGImageRef)backgroundImage 
                                 withOrientation:(UIDeviceOrientation)orientation 
                                     frontFacing:(BOOL)isFrontFacing
{
	CGImageRef returnImage = NULL;
	CGRect backgroundImageRect = CGRectMake(0., 0., CGImageGetWidth(backgroundImage), CGImageGetHeight(backgroundImage));
	CGContextRef bitmapContext = CreateCGBitmapContextForSize(backgroundImageRect.size);
	CGContextClearRect(bitmapContext, backgroundImageRect);
	CGContextDrawImage(bitmapContext, backgroundImageRect, backgroundImage);
	CGFloat rotationDegrees = 0.;
	
	switch (orientation) {
		case UIDeviceOrientationPortrait:
			rotationDegrees = -90.;
			break;
		case UIDeviceOrientationPortraitUpsideDown:
			rotationDegrees = 90.;
			break;
		case UIDeviceOrientationLandscapeLeft:
			if (isFrontFacing) rotationDegrees = 180.;
			else rotationDegrees = 0.;
			break;
		case UIDeviceOrientationLandscapeRight:
			if (isFrontFacing) rotationDegrees = 0.;
			else rotationDegrees = 180.;
			break;
		case UIDeviceOrientationFaceUp:
		case UIDeviceOrientationFaceDown:
		default:
			break; // leave the layer in its last known orientation
	}
	UIImage *rotatedSquareImage = [squarePNG imageRotatedByDegrees:rotationDegrees];
	
    // features found by the face detector
	for ( CIFaceFeature *ff in features ) {
		CGRect faceRect = [ff bounds];
		CGContextDrawImage(bitmapContext, faceRect, [rotatedSquareImage CGImage]);
	}
	returnImage = CGBitmapContextCreateImage(bitmapContext);
	CGContextRelease (bitmapContext);
	
	return returnImage;
}

// utility routine used after taking a still image to write the resulting image to the camera roll
- (BOOL)writeCGImageToCameraRoll:(CGImageRef)cgImage withMetadata:(NSDictionary *)metadata
{
	CFMutableDataRef destinationData = CFDataCreateMutable(kCFAllocatorDefault, 0);
	CGImageDestinationRef destination = CGImageDestinationCreateWithData(destinationData, 
																		 CFSTR("public.jpeg"), 
																		 1, 
																		 NULL);
	BOOL success = (destination != NULL);
	require(success, bail);
    {
	const float JPEGCompQuality = 0.85f; // JPEGHigherQuality
	CFMutableDictionaryRef optionsDict = NULL;
	CFNumberRef qualityNum = NULL;
	
	qualityNum = CFNumberCreate(0, kCFNumberFloatType, &JPEGCompQuality);    
	if ( qualityNum ) {
		optionsDict = CFDictionaryCreateMutable(0, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
		if ( optionsDict )
			CFDictionarySetValue(optionsDict, kCGImageDestinationLossyCompressionQuality, qualityNum);
		CFRelease( qualityNum );
	}
	
	CGImageDestinationAddImage( destination, cgImage, optionsDict );
	success = CGImageDestinationFinalize( destination );
    
	if ( optionsDict ) CFRelease(optionsDict);
	}
    
	require(success, bail);
	{
	CFRetain(destinationData);
	ALAssetsLibrary *library = [ALAssetsLibrary new];
	[library writeImageDataToSavedPhotosAlbum:(__bridge id)destinationData metadata:metadata completionBlock:^(NSURL *assetURL, NSError *error) {
		if (destinationData)
			CFRelease(destinationData);
	}];
	[library release];
    }
    
bail:
    {
	if (destinationData)		CFRelease(destinationData);
	if (destination)		CFRelease(destination);
	return success;
    }
}

// utility routine to display error aleart if takePicture fails
- (void)displayErrorOnMainQueue:(NSError *)error withMessage:(NSString *)message
{
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"%@ (%d)", message, (int)[error code]]
															message:[error localizedDescription]
														   delegate:nil 
												  cancelButtonTitle:@"Dismiss" 
												  otherButtonTitles:nil];
		[alertView show];
		[alertView release];
	});
}

// main action method to take a still image -- if face detection has been turned on and a face has been detected
// the square overlay will be composited on top of the captured image and saved to the camera roll
- (IBAction)takePicture:(id)sender
{
	// Find out the current orientation and tell the still image output.
	AVCaptureConnection *stillImageConnection = [stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	AVCaptureVideoOrientation avcaptureOrientation = [self avOrientationForDeviceOrientation:curDeviceOrientation];
	[stillImageConnection setVideoOrientation:avcaptureOrientation];
	[stillImageConnection setVideoScaleAndCropFactor:effectiveScale];
	
    BOOL doingFaceDetection = detectFaces && (effectiveScale == 1.0);
	
    // set the appropriate pixel format / image type output setting depending on if we'll need an uncompressed image for
    // the possiblity of drawing the red square over top or if we're just writing a jpeg to the camera roll which is the trival case
    if (doingFaceDetection)
		[stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:[NSNumber numberWithInt:kCMPixelFormat_32BGRA] 
																		forKey:(id)kCVPixelBufferPixelFormatTypeKey]];
	else
		[stillImageOutput setOutputSettings:[NSDictionary dictionaryWithObject:AVVideoCodecJPEG 
																		forKey:AVVideoCodecKey]]; 
	
	[stillImageOutput captureStillImageAsynchronouslyFromConnection:stillImageConnection
                    completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
                    if (error) {
                        [self displayErrorOnMainQueue:error withMessage:@"Take picture failed"];
                    }
                    else {
                    if (doingFaceDetection) {
                    // Got an image.
                    CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(imageDataSampleBuffer);
                    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                    CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(NSDictionary *)attachments];
                    if (attachments)
                    CFRelease(attachments);
                                                              
                    NSDictionary *imageOptions = nil;
                    NSNumber * orientation = (__bridge NSNumber*)CMGetAttachment(imageDataSampleBuffer, kCGImagePropertyOrientation, NULL);
                    if (orientation) {
                        imageOptions = [NSDictionary dictionaryWithObject:orientation forKey:CIDetectorImageOrientation];
                    }
                                                              
                    // when processing an existing frame we want any new frames to be automatically dropped
                    // queueing this block to execute on the videoDataOutputQueue serial queue ensures this
                    // see the header doc for setSampleBufferDelegate:queue: for more information
                    dispatch_sync(videoDataOutputQueue, ^(void) {
                                                                  
                    // get the array of CIFeature instances in the given image with a orientation passed in
                    // the detection will be done based on the orientation but the coordinates in the returned features will
                    // still be based on those of the image.
                    NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
                    CGImageRef srcImage = NULL;
                    OSStatus err = CreateCGImageFromCVPixelBuffer(CMSampleBufferGetImageBuffer(imageDataSampleBuffer), &srcImage);
                    check(!err);
                                                                  
                    CGImageRef cgImageResult = [self newSquareOverlayedImageForFeatures:features 
                                                                            inCGImage:srcImage 
                                                                        withOrientation:curDeviceOrientation 
                                                                        frontFacing:isUsingFrontFacingCamera];
                    if (srcImage)   CFRelease(srcImage);
                                                                  
                    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                    [self writeCGImageToCameraRoll:cgImageResult withMetadata:(__bridge id)attachments];
                    if (attachments)   CFRelease(attachments);
                    if (cgImageResult) CFRelease(cgImageResult);
                    });
                                                              
                    [ciImage release];
                }
                else {
                    // trivial simple JPEG case
                    NSData *jpegData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
                    CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, imageDataSampleBuffer, kCMAttachmentMode_ShouldPropagate);
                    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
                    [library writeImageDataToSavedPhotosAlbum:jpegData 
                                                     metadata:(__bridge id)attachments 
                                              completionBlock:^(NSURL *assetURL, NSError *error) {
                                                                  if (error) {
                                                                      [self displayErrorOnMainQueue:error withMessage:@"Save to camera roll failed"];
                                                                  }
                                                              }];
                                                              
                    if (attachments) CFRelease(attachments);
                    [library release];
                }
                }
        }
	 ];
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity frameSize:(CGSize)frameSize apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}

// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector (if on)
// to detect features and for each draw the red square in a layer and set appropriate orientation
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[previewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
	NSString *featureLayerName;
    struct CGImage *featureImage;
	if (eyeLine) {
		featureLayerName = @"EyeLineLayer";
		featureImage = [eyeLinePNG CGImage];
	}
	else {
		featureLayerName = @"FaceLayer";
		featureImage = [squarePNG CGImage];
	}
    
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"]|| [[layer name] isEqualToString:@"EyeLineLayer"] )
			[layer setHidden:YES];
	}	
	
	if ( featuresCount == 0 || !detectFaces ) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [previewView frame].size;
	NSString *gravity = [previewLayer videoGravity];
	BOOL isMirrored = [previewLayer isMirrored];
	CGRect previewBox = [DataFetchViewController videoPreviewBoxForGravity:gravity 
                                                                 frameSize:parentFrameSize 
                                                              apertureSize:clap.size];
	
	for ( CIFaceFeature *ff in features ) {
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect faceRect = [ff bounds];
        /*
        if ( eyeLine && ff.hasLeftEyePosition && ff.hasRightEyePosition) {
			// flip EyePosition
			CGPoint leftEyePosition = CGPointMake(ff.leftEyePosition.y, ff.leftEyePosition.x);
			CGPoint rightEyePosition = CGPointMake(ff.rightEyePosition.y, ff.rightEyePosition.x);
            */
			/*
            // make rect for eyeLine
			CGFloat xAdd = (rightEyePosition.x - leftEyePosition.x) / 3.0f;
			CGFloat yAdd = xAdd / 2.0f;
			if (leftEyePosition.y>rightEyePosition.y) {
				faceRect = CGRectMake(leftEyePosition.x - xAdd, rightEyePosition.y - yAdd,
									  rightEyePosition.x - leftEyePosition.x + xAdd * 2.0f,
									  leftEyePosition.y - rightEyePosition.y + yAdd * 2.0f);
			}
			else {
				faceRect = CGRectMake(leftEyePosition.x- xAdd, leftEyePosition.y - yAdd,
									  rightEyePosition.x - leftEyePosition.x + xAdd * 2.0f,
									  rightEyePosition.y - leftEyePosition.y + yAdd * 2.0f);			
			}
            
            // make rect for left eye
            CGFloat twoEyeDist = rightEyePosition.x - leftEyePosition.x;
			faceRect = CGRectMake(leftEyePosition.x-twoEyeDist/4.0f, leftEyePosition.y-twoEyeDist/8.0f, twoEyeDist/2.0f, twoEyeDist/4.0f);
		}*/
        //else {
		// flip preview width and height
        /*
		CGFloat temp = faceRect.size.width;
		faceRect.size.width = faceRect.size.height;
		faceRect.size.height = temp;
		temp = faceRect.origin.x;
		faceRect.origin.x = faceRect.origin.y;
		faceRect.origin.y = temp;
         */
        CGPoint leftEyePosition = CGPointMake(ff.leftEyePosition.y, ff.leftEyePosition.x);
        CGPoint rightEyePosition = CGPointMake(ff.rightEyePosition.y, ff.rightEyePosition.x);
        CGFloat twoEyeDist = sqrtf((rightEyePosition.x - leftEyePosition.x)*(rightEyePosition.x - leftEyePosition.x)+(rightEyePosition.y - leftEyePosition.y)*(rightEyePosition.y - leftEyePosition.y));
        faceRect = CGRectMake(leftEyePosition.x-twoEyeDist/3.4f, leftEyePosition.y-twoEyeDist/7.5f, twoEyeDist/1.8f, twoEyeDist/3.3f);
        //}
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clap.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clap.size.width;
		faceRect.size.width *= widthScaleBy;
		faceRect.size.height *= heightScaleBy;
		faceRect.origin.x *= widthScaleBy;
		faceRect.origin.y *= heightScaleBy;
        
		if ( isMirrored )
			faceRect = CGRectOffset(faceRect, previewBox.origin.x + previewBox.size.width - faceRect.size.width - (faceRect.origin.x * 2), previewBox.origin.y);
		else
			faceRect = CGRectOffset(faceRect, previewBox.origin.x, previewBox.origin.y);
		
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [CALayer new];
			[featureLayer setContents:(id)[squarePNG CGImage]];
			[featureLayer setName:@"FaceLayer"];
			[previewLayer addSublayer:featureLayer];
			[featureLayer release];
		}
		[featureLayer setFrame:faceRect];
		
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
	}
	
	[CATransaction commit];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{	
	// got an image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer options:(NSDictionary *)attachments];
	if (attachments)
		CFRelease(attachments);
	NSDictionary *imageOptions = nil;
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
	int exifOrientation;
	
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants. 
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.  
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.  
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.  
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.  
	};
	
	switch (curDeviceOrientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    
	imageOptions = [NSDictionary dictionaryWithObject:[NSNumber numberWithInt:exifOrientation] forKey:CIDetectorImageOrientation];
	NSArray *features = [faceDetector featuresInImage:ciImage options:imageOptions];
	[ciImage release];
	
    // get the clean aperture
    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
    // that represents image data valid for display.
	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
	CGRect clap = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);
	
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaceBoxesForFeatures:features forVideoBox:clap orientation:curDeviceOrientation];
	});
    /* Former EyeDetect project
    //NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	//Check the captureImage flag before capture the image
	if (_captureImage ==YES) {
		//NSLog(@"ready to capture image from camera.");
		UIImage *image = [self imageFromSampleBuffer:sampleBuffer];
		if(_settingImage == NO) { 
			//Set the orientation of raw image captured by camera
			image = [self rotateImage:image orientation:UIImageOrientationLeftMirrored]; 
			_settingImage = YES; 
			//NSLog(@"Image been set.");
			//Create new thread to run function for handling captured image
			[NSThread detachNewThreadSelector:@selector(handleCapturedImage:) 
									 toTarget:self
								   withObject:image]; 
		}
        
	}
	//[pool drain];
    */
}


- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    /*Former EyeDetect project
    currentAreaNum = 0;
	imageDataArray = [[NSMutableArray alloc] init];
	positionInfoArray = [[NSMutableArray alloc] initWithCapacity:AreaNum];
	[positionInfoArray addObject:@"1 0 0"];
	NSLog(@"position array: %@",positionInfoArray);
	
	//capturedImage = [[UIImage alloc] init];
	[self setupCaptureSession];
	_settingImage = NO;
	_captureImage = NO;
	
	self._imageView = [[UIImageView alloc] init]; 
	self._imageView.frame = self.view.bounds;
	self._imageView.opaque = YES; 
	self._imageView.alpha = 0.5;
	self._imageView.backgroundColor = [UIColor clearColor];
	self._imageView.contentMode = UIViewContentModeScaleAspectFit;
	[self.view addSubview:self._imageView];
	[self.view bringSubviewToFront:_imageView];
	
	//Start the buttonTimer and call the handler function every intervel
	buttonTimer = [NSTimer scheduledTimerWithTimeInterval:5.0
												   target:self
												 selector:@selector(buttonTimerHandler:)
												 userInfo:[NSString stringWithFormat:@"%d", currentAreaNum]
												  repeats:YES];
    
    */
    /*for eyeline project
    squarePNG = [UIImage imageNamed:@"squarePNG"];
	eyeLinePNG = [UIImage imageNamed:@"eyeLine"];
	
	eyeLine = YES;
    detectFaces = YES;
    
	NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
	faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    
	[self setupAVCapture];
     */
    [self setupAVCapture];
    eyeLine = YES;
    detectFaces = YES;
    [self switchCameras];
    squarePNG = [UIImage imageNamed:@"squarePNG"];
	eyeLinePNG = [UIImage imageNamed:@"eyeLine"];
	//square = [[UIImage imageNamed:@"squarePNG"] retain];
	NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
	faceDetector = [[CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions] retain];
	[detectorOptions release];
    
    
}

- (void)dealloc
{
	[self teardownAVCapture];
	[faceDetector release];
	[square release];
	[super dealloc];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end
