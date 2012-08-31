//
//  LazyLoadImageManager.m
//  SendOutCards
//
//  Created by Riley Crebs on 8/1/12.
//  Copyright (c) 2012 SendOutCards. All rights reserved.
//

#import "ImageManager.h"

#define kLibDirectory [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) objectAtIndex:0]
#define kOrientationPlistFilePath [kLibDirectory stringByAppendingFormat:@"/default/%@", kImageOrientation_Plist]
#define kImageOrientation_Plist @"ImageOrientation.plist"

@interface ImageManager ()
+ (BOOL) _saveImageOrientationForImage:(UIImage*)image withImageName:(NSString*)imageName;
+ (NSMutableDictionary*) defaultImageManagerOrientation ;
@end

@implementation ImageManager {
    dispatch_semaphore_t _lazy_load_semaphore;
}

#pragma mark - Life Cycle Methods
- (id) init {
    self = [super init];
    if (self) {
        _imageCache = [[NSMutableDictionary alloc] init];
        _lazy_load_semaphore = dispatch_semaphore_create(1);
    }
    return self;
}

#pragma mark - Public Methods
- (void) lazyLoadImageFromInternetWithURL:(NSURL*)imageURL forIndexPaht:(NSIndexPath*)indexPath whenLoadedCallDelegate:(id<LazyLoadImageManagerDelegate>)delegate {
    _lazyLoadDelegate = delegate;
    dispatch_async(dispatch_queue_create("com.Incravo.lazyload", NULL), ^{
        dispatch_semaphore_wait(_lazy_load_semaphore, DISPATCH_TIME_FOREVER);
        UIImage *image = [UIImage imageWithData:[NSData dataWithContentsOfURL:imageURL]];
        [_imageCache setObject:image forKey:indexPath];
        dispatch_async(dispatch_get_main_queue(), ^{
            [_lazyLoadDelegate imageCachedAtIndexPath:indexPath];
        });
        dispatch_semaphore_signal(_lazy_load_semaphore);
    });
}

- (UIImage*) imageAtIndexPath:(NSIndexPath*)indexPath {
    return [_imageCache objectForKey:indexPath];
}

+ (void) saveImage:(UIImage*)image fileName:(NSString*)fileName folderName:(NSString*)folderName successBlock:(void(^)(NSString *filePath))success  {
    
    // Create a file path to store images
    NSString *libraryPath = [ImageManager _libraryPathWithFolderName:folderName];
    NSString *filePath = [libraryPath stringByAppendingFormat:@"/%@.png", fileName];
    
    // Write image to disk
    NSData *imageData = UIImagePNGRepresentation(image);
    
    NSError *error = nil;
    if (imageData != nil) {
        
        // Create Library Path
        if ([[NSFileManager defaultManager] createDirectoryAtPath:libraryPath withIntermediateDirectories:YES attributes:nil error:&error] == NO)
            NSLog(@"%@ in %s", error, __PRETTY_FUNCTION__);
        
        
        if ([[NSFileManager defaultManager] createFileAtPath:filePath contents:imageData attributes:nil] == NO)
            NSLog(@"files wasn't written correctly");
        
        if ([ImageManager _saveImageOrientationForImage:image withImageName:fileName] == NO) {
            NSLog(@"Failed to save image orientation");
        }
    }
    
    success(filePath);
}

+ (UIImage*) getImageFileName:(NSString*)fileName inFolderName:(NSString*)folderName {
    // Create a file path to store images
    NSString *libraryPath = [ImageManager _libraryPathWithFolderName:folderName];
    NSString *filePath = [libraryPath stringByAppendingFormat:@"/%@.png", fileName];
    UIImage *image = [UIImage imageWithContentsOfFile:filePath];
    return [[UIImage alloc] initWithCGImage:image.CGImage
                                      scale:1.0f orientation:[ImageManager imageOrientationForImageNamed:fileName]];
}

+ (BOOL) removeItemAtFilePath:(NSString*)filePath {
    return [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
}

#pragma mark - Private Methods
+ (NSString*) _libraryPathWithFolderName:(NSString*)aFolderName {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *pathToLibrary = [paths objectAtIndex:0];
    return [pathToLibrary stringByAppendingFormat:@"/default/%@/images", aFolderName];
}

+ (BOOL) _saveImageOrientationForImage:(UIImage*)image withImageName:(NSString*)imageName {
    NSMutableDictionary *orientationData = [ImageManager defaultImageManagerOrientation];
    [orientationData setObject:[NSNumber numberWithInt:image.imageOrientation] forKey:imageName];
    return [orientationData writeToFile:kOrientationPlistFilePath atomically:YES];
}

+ (UIImageOrientation) imageOrientationForImageNamed:(NSString*)imageName {
    NSDictionary *imageOrientationData = [ImageManager defaultImageManagerOrientation];
    return [[imageOrientationData valueForKey:imageName] intValue];
}

+ (NSMutableDictionary*) defaultImageManagerOrientation {
    
    NSMutableDictionary *dictionary = nil;
    if([[NSFileManager defaultManager] fileExistsAtPath:kOrientationPlistFilePath] == NO) {
        dictionary = [[NSMutableDictionary alloc] init];
        [dictionary writeToFile:kOrientationPlistFilePath atomically:YES];
    }
    else {
        dictionary = [NSMutableDictionary dictionaryWithContentsOfFile:kOrientationPlistFilePath];
    }
    
    return dictionary;
}

@end
