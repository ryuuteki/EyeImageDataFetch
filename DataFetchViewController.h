//
//  ViewController.h
//  EyeImageDataFetch
//
//  Created by Liu Di on 6/2/12.
//  Copyright (c) 2012 Hiroshima University. All rights reserved.
//


#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import <CoreImage/CoreImage.h>
#import <CoreGraphics/CoreGraphics.h>
#import <CoreVideo/CoreVideo.h>
#import <CoreMedia/CoreMedia.h>
#import <ImageIO/ImageIO.h>
#import <AssertMacros.h>
#import <AssetsLibrary/AssetsLibrary.h>
//#import "EyesDetection.h"
//#import "EyesCrop.h"
//#import "FaceDetect.h"
//#import "ImageTransfer.h"


#define AreaNum 6
#define eyeImageSize 600


@interface DataFetchViewController : UIViewController <AVCaptureVideoDataOutputSampleBufferDelegate>{
	IBOutlet UIButton *button1;
	IBOutlet UIButton *button2;
	IBOutlet UIButton *button3;
	IBOutlet UIButton *button4;
	IBOutlet UIButton *button5;
	IBOutlet UIButton *button6;
	NSTimer *buttonTimer;
	NSTimer *fetchDataTimer;
	NSInteger currentAreaNum;
	NSMutableArray *imageDataArrary;
	NSMutableArray *positionInfoArrary;
	
	AVCaptureSession *_session;
	AVCaptureVideoPreviewLayer *_prevLayer;
	UIImageView *_imageView;
	
	BOOL _settingImage;
	BOOL _captureImage;
    
    IBOutlet UIView *previewView;
	IBOutlet UISwitch *faceSwitch;
	AVCaptureVideoPreviewLayer *previewLayer;
	AVCaptureVideoDataOutput *videoDataOutput;
	dispatch_queue_t videoDataOutputQueue;
	CIDetector *faceDetector;
	UIImage *squarePNG;
	UIImage *eyeLinePNG;
	BOOL eyeLine;
    
	IBOutlet UISegmentedControl *camerasControl;
	BOOL detectFaces;
	AVCaptureStillImageOutput *stillImageOutput;
	UIView *flashView;
	UIImage *square;
	BOOL isUsingFrontFacingCamera;
	CGFloat beginGestureScale;
	CGFloat effectiveScale;
    
}

@property (retain, nonatomic) IBOutlet UIButton *button1;
@property (retain, nonatomic) IBOutlet UIButton *button2;
@property (retain, nonatomic) IBOutlet UIButton *button3;
@property (retain, nonatomic) IBOutlet UIButton *button4;
@property (retain, nonatomic) IBOutlet UIButton *button5;
@property (retain, nonatomic) IBOutlet UIButton *button6;
@property (retain, nonatomic) NSTimer *buttonTimer;
@property (retain, nonatomic) NSTimer *fetchDataTimer;
@property (retain, nonatomic) NSMutableArray *imageDataArray;
@property (retain, nonatomic) NSMutableArray *positionInfoArray;

@property (retain, nonatomic) AVCaptureSession *_session;
@property (retain, nonatomic) UIImageView *_imageView;
@property (retain, nonatomic) UIImage *capturedImage;

-(void)buttonTimerHandler:(NSTimer *) timer;
-(void)fetchDataTimerHandler:(NSTimer *) timer;
-(void)clearButtonsColor;
-(void)highlightButtons;
-(void)stopTimer: (NSTimer *) timer;
-(void)saveImageDataToFile: (NSMutableArray *)image withPositionInfo: (NSMutableArray *)position;

-(void)setupCaptureSession;
-(AVCaptureDevice *)frontFacingCameraIfAvailable;
-(UIImage *) imageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer;
-(UIImage *) rotateImage:(UIImage*)image orientation:(UIImageOrientation) orient;
-(void)handleCapturedImage: (UIImage *)image;

- (IBAction)touchSwitch:(id)sender;
- (IBAction)takePicture:(id)sender;
- (IBAction)switchCameras;
- (IBAction)handlePinchGesture:(UIGestureRecognizer *)sender;
- (IBAction)toggleFaceDetection:(id)sender;
- (void)teardownAVCapture;
- (void)drawFaceBoxesForFeatures:(NSArray *)features forVideoBox:(CGRect)clap orientation:(UIDeviceOrientation)orientation;



@end
