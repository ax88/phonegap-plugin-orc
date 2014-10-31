//  EmptyPlugin.h
//
//  Created by Pierre-Emmanuel Bois on 08/08/13.
//
//  Copyright 2012-2013 Pierre-Emmanuel Bois. All rights reserved.
//  MIT Licensed

#import <Cordova/CDV.h>
#import <UIKit/UIKit.h>
#import "GKImageCropViewController.h"
#import <TesseractOCR/TesseractOCR.h>

@interface OCR : CDVPlugin <GKImageCropControllerDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, TesseractDelegate> {
}

@property NSString *callbackId;

- (void)scan:(CDVInvokedUrlCommand*)command;
@end
