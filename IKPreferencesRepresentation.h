//
//  IKPreferencesRepresentation.h
//  IKApplicationPreferencesDemo
//
//  Created by Ilya Kulakov on 01.11.12.
//  Copyright (c) 2012 Ilya Kulakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@protocol IKPreferencesRepresentation <NSObject>

/*!
    @brief  Returns view that representes user's preferences.
 */
- (NSView *)view;

/*!
    @brief  Configures toolbar item properties other than target and action.
 */
- (void)configureToolbarItem:(NSToolbarItem *)anItem;

@optional

/*!
 @brief         Returns title that represents user's preferences. CAN be nil.
 @discussion    If KVO-compliant, window of IKApplicationPreferences will respond to updates.
 */
- (NSString *)title;

@end
