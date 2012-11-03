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
    @discussion Title of the window is bound to title of selectedRepresentation. If value for that binding is nil or not applicable,
                titlePlaceholder is used.


                If you use default template, then _representationsRootView is an instance of _IKRepresentationRootView and therefore is flipped.


                Common reasons to subclass are:


                - Custom toolbar management. Subclass and override delegate methods. If you want to customize it
                override windowDidLoad as well


                - Advanced window size management


                - Custom title placeholder
 */
@interface IKApplicationPreferences : NSWindowController<NSWindowDelegate, NSToolbarDelegate>
{
    IBOutlet NSView *_representationsRootView;
}

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
    @see        selectedRepresentation
    @see        setSelectedRepresentationIdentifier:animated:
 */
@property (nonatomic, copy) NSString *selectedRepresentationIdentifier;

/*!
    @brief      Returns window controller initialized with a nib file and configured toolbar.
    @param      aNibName The name of the nib file (minus the “.nib” extension) that archives the receiver’s window. CANNOT be nil.
    @param      aFormat Comma-separated that specifies appearance and order of toolbar items. CANNOT be nil.
                When specifying format, you can use ' ' as a shortcut of NSToolbarSpaceItemIdentifier
                and '-' as a shortcut of NSToolbarFlexibleSpaceItemIdentifier.
    @param      aRepresentations A dictionary of representations that appear in the visual format string.
                The keys MUST be the string values used in the visual format string, and the values must be the NSObject<IKPreferencesRepresentation> objects.
    @param      aUsesCoreAnimation Determines whether animation is powered by Core Animation or not.
    @discussion This method is the designated initializer for IKApplicationPreferences.
                Example of visual format string: \@"general, ,video,sound,-,about"
 */
- (instancetype)initWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations usesCoreAnimation:(BOOL)aUsesCoreAnimation;

/*!
    @brief      Returns window controller initialized with a nib file and configured toolbar.
    @discussion If target version of Mac OS X is 10.8+, it will use core animation.
 */
+ (instancetype)preferencesWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations;

/*!
    @brief      Expands shortcuts into normal identifiers.
    @param      aFormatWithShortcuts Format string to expand.
    @discussion Default implementation expands ' ' into NSToolbarSpaceItemIdentifier and '-' into NSToolbarFlexibleSpaceItemIdentifier
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
- (void)setSelectedRepresentationIdentifier:(NSString *)newIdentifier animated:(BOOL)isAnimated;

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
    @discussion You SHOULD not send this message directly. It's typically sent automatically by toolbar items.
 */
- (void)toggleRepresentationForToolbarItem:(NSToolbarItem *)anItem;

/*!
    @brief      Returns window size for a given size of representation view.
    @param      aRepresentationViewSize Size of the representation view.
    @dicussion  You MUST override the class if you provide layout when spaces between
                _representationsRootView edges and the window edges may change.
 */
- (NSRect)windowFrameForRepresentationViewSize:(NSSize)aRepresentationViewSize;

/*!
    @brief      Adjusts window's size only.
    @param      aRepresentationViewSize New size of the representation view.
    @param      isAnimated Determines whether appearance of new representation should be animated.
    @discussion It uses windowFrameForRepresentationViewSize: do determine size of the window.
    @see        windowFrameForRepresentationViewSize:
 */
- (void)adjustWindowSizeToMatchRepresentationViewSize:(NSSize)newSize animated:(BOOL)isAnimated;

/*!
    @brief      Adjusts both window's and selectedRepresentation view's sizes.
    @param      aRepresentationViewSize New size of the representation view.
    @param      isAnimated Determines whether appearance of new representation should be animated.
    @discussion It uses windowFrameForRepresentationViewSize: do determine size of the window.
                You MUST override this method for the same reasons as windowFrameForRepresentationViewSize:
    @see        windowFrameForRepresentationViewSize:
 */
- (void)adjustWindowAndRepresentationViewSizesToMatchRepresentationViewSize:(NSSize)newSize animated:(BOOL)isAnimated;

/*!
    @brief      Returns localized placeholder for title if representation's title is not applicable for some reason.
 */
- (NSString *)titlePlaceholder;

@end
