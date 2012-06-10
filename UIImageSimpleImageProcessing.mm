/*
 * Copyright (c) 2011 b2cloud
 * By Will Sackfield
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for specific language governing permissions and
 * limitations under the License.
 *
 * File: UIImage+simple-image-processing.mm
 *
 * 1.0 (13/09/2011)
 */
#import "UIImageSimpleImageProcessing.h"
#import "Image.h"

@implementation UIImage (UIImage_simple_image_processing)

// Resize the image the size given by a CGSize element
-(UIImage*) imageResize:(CGSize)size
{
	// Create an image object with the current UIImage and the new size
	return Image::createImage(self,size.width,size.height).image->toUIImage();
}

// Extract the edges using a canny edge extraction based on the low and high values
// http://en.wikipedia.org/wiki/Canny_edge_detector
-(UIImage*) imageByCannyEdgeExtractionLow:(CGFloat)low high:(CGFloat)high
{
	// Create an image object with the current UIImage and size then perform the canny edge extraction
	return Image::createImage(self,self.size.width,self.size.height).image->cannyEdgeExtract(low,high).image->toUIImage();
}

// Perform automatic local threshold
// http://en.wikipedia.org/wiki/Thresholding_(image_processing)#Adaptive_thresholding
-(UIImage*) imageByLocalThreshold
{
	// Create an image object with the current UIImage and size then perform the automatic local thresholding
	return Image::createImage(self,self.size.width,self.size.height).image->autoLocalThreshold().image->toUIImage();
}

// Perform thresholding using the entire image as a threshold
// http://en.wikipedia.org/wiki/Thresholding_(image_processing)
-(UIImage*) imageByThresholding
{
	// Create an image object with the current UIImage and size then perform the automatic thresholding
	return Image::createImage(self,self.size.width,self.size.height).image->autoThreshold().image->toUIImage();
}

// Perform a gaussian blur on an image
// http://en.wikipedia.org/wiki/Gaussian_blur
-(UIImage*) imageByGaussianBlur
{
	// Create an image object with the current UIImage and size then perform a gaussian blur
	return Image::createImage(self,self.size.width,self.size.height).image->gaussianBlur().image->toUIImage();
}

// Extract a connected region from an image
// http://en.wikipedia.org/wiki/Blob_extraction
-(NSArray*) connectedRegionFromPoint:(CGPoint)point
{
	// Create a vector to store our image points
	std::vector<ImagePoint> imagePoints;
	// Create an ImageWrapper object from our current UIImage and size and extract the connected region into the vector
	Image::createImage(self,self.size.width,self.size.height).image->extractConnectedRegion(point.x,point.y,&imagePoints);
	// Create an NSMutableArray to hold our points
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:imagePoints.size()];
	// Loop through our image points vector
	for(std::vector<ImagePoint>::iterator i=imagePoints.begin();i!=imagePoints.end();i++)
	{
		// Discover the image point we are referencing (I actually think this is a really cool way to use pointers)
		ImagePoint imagePoint = *i;
		// Create a CGPoint object and add it to the points array
		[points addObject:[NSValue valueWithCGPoint:CGPointMake(imagePoint.x,imagePoint.y)]];
	}
	// Return our points
	return points;
}

// Extract the largest region from an image
-(NSArray*) largestRegion
{
	// Create a vector to store our image points
	std::vector<ImagePoint> imagePoints;
	// Create an ImageWrapper object from our current UIImage and size and find the largest connected structure
	Image::createImage(self,self.size.width,self.size.height).image->findLargestStructure(&imagePoints);
	// Create an NSMutableArray to hold our points
	NSMutableArray* points = [NSMutableArray arrayWithCapacity:imagePoints.size()];
	// Loop through our image points vector
	for(std::vector<ImagePoint>::iterator i=imagePoints.begin();i!=imagePoints.end();i++)
	{
		// Discover the image point we are referencing (I actually think this is a really cool way to use pointers)
		ImagePoint imagePoint = *i;
		// Create a CGPoint object and add it to the points array
		[points addObject:[NSValue valueWithCGPoint:CGPointMake(imagePoint.x,imagePoint.y)]];
	}
	// Return our points
	return points;
}

// Perform normalisation on an image
// http://en.wikipedia.org/wiki/Normalization_(image_processing)
-(UIImage*) imageByNormalising
{
	// Create an ImageWrapper object from our current UIImage and size
	ImageWrapper* normalisedImage = Image::createImage(self,self.size.width,self.size.height);
	// Normalise it
	normalisedImage.image->normalise();
	// Return a UIImage
	return normalisedImage.image->toUIImage();
}

// Rotate the image (in radians)
-(UIImage*) imageRotate:(CGFloat)radians
{
	// Create an ImageWrapper object from our current UIImage and size then return it with the rotation
	return Image::createImage(self,self.size.width,self.size.height).image->rotate((int)(radians*(180.0/M_PI))).image->toUIImage();
}

// Perform histogram equalisation on an image
// http://en.wikipedia.org/wiki/Histogram_equalisation
-(UIImage*) imageByHistogramEqualisation
{
	// Create an ImageWrapper object from our current UIImage and size
	ImageWrapper* histogramImage = Image::createImage(self,self.size.width,self.size.height);
	// Perform histogram equalisation
	histogramImage.image->HistogramEqualisation();
	// Return a UIImage
	return histogramImage.image->toUIImage();
}

// Perform topological skeleton on an image
// http://en.wikipedia.org/wiki/Topological_skeleton
-(UIImage*) imageByTopologicalSkeleton
{
	// Create an ImageWrapper object from our current UIImage and size
	ImageWrapper* skeletonImage = Image::createImage(self,self.size.width,self.size.height);
	// Create a topological skeleton
	skeletonImage.image->skeletonise();
	// Return a UIImage
	return skeletonImage.image->toUIImage();
}

// Turn an array of CGPoints into a CGRect (if you want to box objects)
-(CGRect) rectForImagePoints:(NSArray*)points
{
	// Setup our minimum and maximum values
	CGFloat minX = MAXFLOAT;
	CGFloat maxX = -MAXFLOAT;
	CGFloat minY = MAXFLOAT;
	CGFloat maxY = -MAXFLOAT;
	// Loop through the values in the array
	for(NSValue* value in points)
	{
		// Extract the CGPoint from the NSValue
		CGPoint point = [value CGPointValue];
		// Reassign our minimum and maximum values
		minX = MIN(minX,point.x);
		maxX = MAX(maxX,point.x);
		minY = MIN(minY,point.y);
		maxY = MAX(maxY,point.y);
	}
	// Return a rectangle representing our extracted area
	return CGRectMake(minX,minY,maxX-minX,maxY-minY);
}

@end
