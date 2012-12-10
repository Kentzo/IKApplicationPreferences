//
//  IKApplicationPreferences.h
//  IKApplicationPreferences
//
//  Created by Ilya Kulakov on 30.10.12.
//  Copyright (c) 2012 Ilya Kulakov. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "IKPreferencesRepresentation.h"


/*!
    @brief      IKApplicationPreferences allows you to easily add preferences to your app.

    @discussion Initialize the class with preferences representations then use showWindow: to show the window preferences.
 */
@interface IKApplicationPreferences : NSWindowController<NSWindowDelegate, NSToolbarDelegate>
{
    IBOutlet NSView *_representationsRootView;
}

/*!
    @brief      Determines whether Core Animation is used to show smooth animations.

    @discussion If YES, then root view of the preferences window wants a layer.
 */
@property (readonly) BOOL usesCoreAnimation;

/*!
    @brief  Representations used to show preferences.
 */
@property (readonly) NSDictionary *representations;

/*!
    @brief      Currently selected representation.

    @discussion KVO-compliant.

    @see        selectedRepresentationIdentifier
 */
@property (readonly) NSObject<IKPreferencesRepresentation> *selectedRepresentation;

/*!
    @brief      Currently selected representation identifier.

    @discussion KVO-compliant. Not animated.

    @see        setSelectedRepresentationIdentifier:animated:
 */
@property (nonatomic, copy) NSString *selectedRepresentationIdentifier;

/*!
    @brief      Returns window controller initialized with a nib file and configured toolbar.

    @param      aNibName The name of the nib file (minus the “.nib” extension) that archives the receiver’s window. CANNOT be nil.

    @param      aFormat Comma-separated list that specifies appearance and order of toolbar items. CANNOT be nil.

    @param      aRepresentations A dictionary of representations that appear in the visual format string.
                The keys MUST be the string values used in the visual format string, and the values must be the NSObject<IKPreferencesRepresentation> objects.

    @param      aUsesCoreAnimation Determines whether Core Animation is used to to show smooth animations.

    @discussion This method is the designated initializer for IKApplicationPreferences.

                When specifying format, you can use ' ' as a shortcut of NSToolbarSpaceItemIdentifier
                and '-' as a shortcut of NSToolbarFlexibleSpaceItemIdentifier.

                Example of visual format string: \@"general, ,video,sound,-,about"
 */
- (instancetype)initWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations usesCoreAnimation:(BOOL)aUsesCoreAnimation;

/*!
    @brief      Returns window controller initialized with a nib file and configured toolbar.

    @discussion If target version of Mac OS X is 10.8+, it will use core animation.

    @see        initWithWindowNibName:visualFormat:representations:usesCoreAnimation:
 */
+ (instancetype)preferencesWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations;

/*!
    @brief      Expands shortcuts into normal identifiers.

    @param      aFormatWithShortcuts Format string to expand.

    @discussion Default implementation expands ' ' into NSToolbarSpaceItemIdentifier
                and '-' into NSToolbarFlexibleSpaceItemIdentifier.
 */
+ (NSString *)visualFormatByExpandingShortcuts:(NSString *)aFormatWithShortcuts;

/*!
    @brief  Returns representation for a given identifier or nil.

    @param  anIdentifier Identifier of a representation.
 */
- (NSObject<IKPreferencesRepresentation> *)representationForIdentifier:(NSString *)anIdentifier;

/*!
    @brief  Selects new representation for a given identifier or does nothing if it's not present.

    @param  newIdentifier New identifier to select.

    @param  isAnimated Determines whether appearance of new representation should be animated.
*/
- (void)setSelectedRepresentationIdentifier:(NSString *)newIdentifier animated:(BOOL)anIsAnimated;

/*!
    @brief      Brings view of selected view representation to the window.

    @discussion You SHOULD NOT need to call this method directly. But you can override it to provide custom functionality.
 */
- (void)showSelectedRepresentationAnimated:(BOOL)anIsAnimated;

/*!
    @brief  Сyclically selects next representation according to visual format used to initialize the object.

    @param  isAnimated Determines whether appearance of new representation should be animated
 */
- (void)showNextRepresentationAnimated:(BOOL)isAnimated;

/*!
    @brief  Сyclically selects previous representation according to visual format used to initialize the object.

    @param  isAnimated Determines whether appearance of new representation should be animated
 */
- (void)showPreviousRepresentationAnimated:(BOOL)isAnimated;

/*!
    @brief      Toggles currently selected representation according to anItem.

    @param      anItem Item that sent the action.

    @discussion You SHOULD NOT need to call this method directly. It's called automatically by toolbar items.
 */
- (void)toggleRepresentationForToolbarItem:(NSToolbarItem *)anItem;

/*!
    @brief  Calculates and returns window frame for desired representation view size.

    @param  aRepresentationViewSize Desired representation view size.
 */
- (NSRect)windowFrameForRepresentationViewSize:(NSSize)aRepresentationViewSize;

/*!
    @brief      Adjusts window size to match currently selected representation view size.

    @param      anIsAnimated Determines whether resize is animated.

    @discussion Does not change size of the selected representation view.
 */
- (void)adjustWindowSizeAnimated:(BOOL)anIsAnimated;

/*!
    @brief      Sets new frame size of selected representation view and adjusts window size simultaneously.

    @param      newSize New frame size of the selected representation view.

    @param      anIsAnimated Determines whether resize is animated.

    @discussion It's the best way if you want change frame size of the represention view.
 */
- (void)setSelectedRepresentationViewSize:(NSSize)newSize animated:(BOOL)anIsAnimated;

/*!
    @brief      Returns localized placeholder for title if representation's title is not applicable for some reason.
 */
- (NSString *)titlePlaceholder;

@end
