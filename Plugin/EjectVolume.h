//
//  EjectVolumeView.h
//  EjectVolume
//
//  Created by Frane Bandov on 10.07.10.
//  Copyright __MyCompanyName__ 2010. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <Carbon/Carbon.h>

@interface EjectVolume : NSObject
{
	NSString *iconDir;
}

-(NSString *) getIconFor:(NSString *)volume;
-(NSArray *) getVolumes;
-(BOOL) unmountVolume:(NSString *)volumePath;
-(void) clearCacheDir;
-(void) logMessage:(NSString *)str;
@end
