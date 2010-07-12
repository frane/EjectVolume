//
//  EjectVolumeView.m
//  EjectVolume
//
//  Created by Frane Bandov on 10.07.10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import "EjectVolume.h"

@implementation EjectVolume


-(id)initWithWebView:(WebView*)w
{
	//NSLog(@"Entering -initWithWebView:%@", w);
	self = [super init];
	srand(time(NULL));
	
	BOOL isDir;
	iconDir = [[NSString alloc] initWithString:[@"~/Library/Caches/EjectVolume/" stringByExpandingTildeInPath]];
    if (![[NSFileManager defaultManager] fileExistsAtPath:iconDir isDirectory:&isDir] || !isDir){
		[[NSFileManager defaultManager] createDirectoryAtPath:iconDir attributes:nil];
	}
	return self;
}

-(void)dealloc
{
	[super dealloc];
}

-(void)windowScriptObjectAvailable:(WebScriptObject*)wso
{
	[wso setValue:self forKey:@"EjectVolume"];
}

+(NSString*)webScriptNameForSelector:(SEL)aSel
{
	NSString *retval = nil;
	//NSLog(@"webScriptNameForSelector");
	if (aSel == @selector(getVolumes)) {
		retval = @"getVolumes";
	} else if (aSel == @selector(unmountVolume:)) {
		retval = @"unmountVolume";
	} else if (aSel == @selector(clearCacheDir)) {
		retval = @"clearCacheDir";
	} else if (aSel == @selector(logMessage:)) {
		retval = @"logMessage";
	} else {
		NSLog(@"\tunknown selector");
	}
	return retval;
}

+(BOOL)isSelectorExcludedFromWebScript:(SEL)aSel {
	if (aSel == @selector(getVolumes) || aSel == @selector(unmountVolume:) || aSel == @selector(clearCacheDir) || aSel == @selector(logMessage:)) {
		return NO;
	}
	return YES;
}

+(BOOL)isKeyExcludedFromWebScript:(const char*)k {
	return YES;
}

-(NSArray *) getVolumes {
	NSMutableArray *volumesOfInterest = [[NSMutableArray alloc] init];
	NSArray *volumes = [[NSWorkspace sharedWorkspace] mountedLocalVolumePaths];
	
    NSString *volume = nil;
	for (int i = 0; i < [volumes count]; i++)
    {
		volume = [volumes objectAtIndex:i];
		if ([volume rangeOfString:@"/Volumes/"].length > 0) {
			[volumesOfInterest addObject:[NSArray arrayWithObjects:[[NSFileManager defaultManager] displayNameAtPath:volume],
										  volume,
										  [self getIconFor:volume], nil]];
		}
    }
    return volumesOfInterest;
}

-(NSString *) getIconFor:(NSString *)volume {
	NSString *iconPath = [NSString stringWithFormat:@"%@/%@.tiff", iconDir, [[NSFileManager defaultManager] displayNameAtPath:volume]];
	if([[NSFileManager defaultManager] fileExistsAtPath:iconPath] == NO) {
		NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:volume];       
		NSArray *iconRepresentations = [icon representations];
		if([iconRepresentations count] > 0){			
			float smallestSize = FLT_MAX;
			int smallestIcon = 0;
			
			for(int i = 0; i < [iconRepresentations count]; i++){
				NSSize iconSize = [[iconRepresentations objectAtIndex:i] size];
				if(iconSize.width < smallestSize && iconSize.width > 16){
					smallestSize = iconSize.width;
					smallestIcon = i;
				}
			}
			NSImageRep *imageRepresnatation = [iconRepresentations objectAtIndex:smallestIcon];
			NSImage *smallIcon = [[NSImage alloc] initWithSize:[imageRepresnatation size]];
			[smallIcon addRepresentation:imageRepresnatation];
			
			NSData *tiffRep = [smallIcon TIFFRepresentation];
			[tiffRep writeToFile:iconPath atomically:YES];
			[smallIcon release];
		} else
			iconPath = @"";
	}
	return iconPath;
}

-(BOOL) unmountVolume:(NSString *)volumePath {
	NSString *iconPath = [NSString stringWithFormat:@"%@/%@.tiff", iconDir, [[NSFileManager defaultManager] displayNameAtPath:volumePath]];
	
	// This somehow refuses to unmount half of the volumes - why???
	// BOOL volumeIsUnmounted = [[NSWorkspace sharedWorkspace] unmountAndEjectDeviceAtPath:volumePath];
	// Good ol' Carbon to the rescue...
	
	BOOL volumeIsUnmounted = NO;
	FSRef ref;
	pid_t dissenter;
	FSCatalogInfo catalogInfo;

	if(noErr == FSPathMakeRef([volumePath fileSystemRepresentation], &ref, NULL)) {			
		if(noErr == FSGetCatalogInfo(&ref, kFSCatInfoVolume, &catalogInfo, NULL, NULL, NULL)) {
			volumeIsUnmounted = noErr == FSEjectVolumeSync(catalogInfo.volume, NULL, &dissenter);
		}
	}
		
	if (volumeIsUnmounted) {
		if([[NSFileManager defaultManager] removeFileAtPath:iconPath handler:nil] == NO) {
			NSLog(@"EjectVolume error: Could not remove cached icon %@", iconPath);
		}
	}
	
	return volumeIsUnmounted;
}

-(void) clearCacheDir {
	NSDirectoryEnumerator *dirEnum = [[NSFileManager defaultManager] enumeratorAtPath:iconDir];
	
	NSString *file;
	while (file = [dirEnum nextObject]) {
		NSLog(@"EJV: %@, %@", iconDir, file);
		[[NSFileManager defaultManager] removeFileAtPath: [iconDir stringByAppendingFormat:@"/%@", file] handler:nil];
	}
							   
}

-(void) logMessage:(NSString *)str {
	NSLog(@"EjectVolume says: %@", str);
}
@end
