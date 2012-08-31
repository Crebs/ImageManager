//
//  LazyLoadImageManager.h
//  SendOutCards
//
//  Created by Riley Crebs on 8/1/12.
//  Copyright (c) 2012 SendOutCards. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LazyLoadImageManagerDelegate <NSObject>

- (void) imageCachedAtIndexPath:(NSIndexPath*)indexPath;

@end

@interface ImageManager : NSObject {
    NSMutableDictionary *_imageCache;
    id<LazyLoadImageManagerDelegate> _lazyLoadDelegate;
}

// Get image
+ (UIImage*) getImageFileName:(NSString*)fileName inFolderName:(NSString*)folderName;

/***************
 *   Lazy load images from a web url.  These methods are designed to work with table views.
 **************/
- (void) lazyLoadImageFromInternetWithURL:(NSURL*)imageURL forIndexPaht:(NSIndexPath*)indexPath whenLoadedCallDelegate:(id<LazyLoadImageManagerDelegate>)delegate;
- (UIImage*) imageAtIndexPath:(NSIndexPath*)indexPath;

/**************
 *   Save images to disk
 *************/
+ (void) saveImage:(UIImage*)image fileName:(NSString*)fileName folderName:(NSString*)folderName successBlock:(void(^)(NSString *filePath))success;

/**************
 *   Remove image from disk
 *************/
+ (BOOL) removeItemAtFilePath:(NSString*)filePath;
@end
