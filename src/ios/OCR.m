//  EmptyPlugin.m
//
//  Created by Pierre-Emmanuel Bois on 08/08/13.
//
//  Copyright 2012-2013 Pierre-Emmanuel Bois. All rights reserved.
//  MIT Licensed

#import "OCR.h"
#import <Cordova/CDV.h>
#define CDV_PHOTO_PREFIX @"cdv_photo_"

@implementation OCR

- (void)scan:(CDVInvokedUrlCommand*)command {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.callbackId = command.callbackId;
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypeCamera;
        picker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        picker.showsCameraControls = YES;
        [self.viewController presentViewController:picker animated:YES completion:nil];
    });
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
   UIImage* image = nil;
   GKImageCropViewController *cropController = [[GKImageCropViewController alloc] init];
   cropController.contentSizeForViewInPopover = picker.contentSizeForViewInPopover;
   image = [info objectForKey:UIImagePickerControllerOriginalImage];
   image = [self imageCorrectedForCaptureOrientation:image];
   cropController.sourceImage = image;
   cropController.resizeableCropArea = YES;
   cropController.cropSize = CGSizeMake(280, 280);
   cropController.delegate = self;
   [picker pushViewController:cropController animated:YES];
}

- (void)imageCropController:(GKImageCropViewController *)imageCropController didFinishWithCroppedImage:(UIImage *)croppedImage{
    Tesseract* tesseract = [[Tesseract alloc] initWithLanguage:@"eng+fra"];
    tesseract.delegate = self;
    //[tesseract setVariableValue:@"0123456789" forKey:@"tessedit_char_whitelist"]; //limit search
    [tesseract setImage:[croppedImage blackAndWhite]]; //image to check
    [tesseract recognize];
    NSString *scannedText = [[tesseract recognizedText] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    CDVPluginResult* result = nil;
    result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:scannedText];
    if (result) [self.commandDelegate sendPluginResult:result callbackId:self.callbackId];
    tesseract = nil;
    [imageCropController dismissViewControllerAnimated:YES completion:nil];
}

- (void)cancelCropController:(GKImageCropViewController *)picker{
    [[picker parentViewController] dismissViewControllerAnimated:YES completion:^{

    }];
}

- (UIImage*)imageCorrectedForCaptureOrientation:(UIImage*)anImage
{
    float rotation_radians = 0;
    bool perpendicular = false;

    switch ([anImage imageOrientation]) {
        case UIImageOrientationUp :
            rotation_radians = 0.0;
            break;

        case UIImageOrientationDown:
            rotation_radians = M_PI;
            break;

        case UIImageOrientationRight:
            rotation_radians = M_PI_2;
            perpendicular = true;
            break;

        case UIImageOrientationLeft:
            rotation_radians = -M_PI_2;
            perpendicular = true;
            break;

        default:
            break;
    }

    UIGraphicsBeginImageContext(CGSizeMake(anImage.size.width, anImage.size.height));
    CGContextRef context = UIGraphicsGetCurrentContext();

    // Rotate around the center point
    CGContextTranslateCTM(context, anImage.size.width / 2, anImage.size.height / 2);
    CGContextRotateCTM(context, rotation_radians);

    CGContextScaleCTM(context, 1.0, -1.0);
    float width = perpendicular ? anImage.size.height : anImage.size.width;
    float height = perpendicular ? anImage.size.width : anImage.size.height;
    CGContextDrawImage(context, CGRectMake(-width / 2, -height / 2, width, height), [anImage CGImage]);

    // Move the origin back since the rotation might've change it (if its 90 degrees)
    if (perpendicular) {
        CGContextTranslateCTM(context, -anImage.size.height / 2, -anImage.size.width / 2);
    }

    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (BOOL)shouldCancelImageRecognitionForTesseract:(Tesseract*)tesseract
{
    return NO;  // return YES, if you need to interrupt tesseract before it finishes
}

@end
