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
                The autoresizing mask is also set to NSViewWidthSizable | NSViewHeightSizable | NSViewMaxXMargin | NSViewMinYMargin.
                If you want to change autoresizing masks, use layout constraints or provide custom layout you have to subclass and override adjustWindowSizeAnimated.


                If _representationsRootView wants a layer, animation used to show/hide representations will use Core Animation and generally much smoother.
                It's recommended to set _representationsRootView to want a layer if OS is 10.8 and higher.


                If _representationsRootView does not want a layer, _representationsRootView is hidden while window is resizing.
                If resizing is not needed, new representation appears immediately.


                Common reasons to subclass are:


                - Custom toolbar management. Subclass and override delegate methods. If you want to configure it
                override windowDidLoad as well.


                - Advanced window size management.


                - Custom title placeholder.
 */
@interface IKApplicationPreferences : NSWindowController<NSWindowDelegate, NSToolbarDelegate>
{
    IBOutlet NSView *_representationsRootView;
}

/*!
    @brief      Returns window controller initialized with a nib file and configured toolbar.
    @param      aNibName The name of the nib file (minus the “.nib” extension) that archives the receiver’s window. CANNOT be nil.
    @param      aFormat Comma-separated that specifies appearance and order of toolbar items. CANNOT be nil.
                When specifying format, you can use ' ' as a shortcut of NSToolbarSpaceItemIdentifier
                and '-' as a shortcut of NSToolbarFlexibleSpaceItemIdentifier.
    @param      aRepresentations A dictionary of representations that appear in the visual format string.
                The keys MUST be the string values used in the visual format string, and the values must be the NSObject<IKPreferencesRepresentation> objects.
    @discussion This method is the designated initializer for IKApplicationPreferences.
                Example of visual format string: \@"general, ,video,sound,-,about"
 */
- (instancetype)initWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations;

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
    @param  isAnimated Determines whether appearance of new representation should be animated
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
    @brief      Adjusts size of the window according to representation view's size.
    @discussion By default it assumes that _representationsRootView edges are not moved relative to the window during resize.
                You should override this method if you want to provide custom layout.
 */
- (void)adjustWindowSizeAnimated:(BOOL)isAnimated;

/*!
    @brief      Returns localized placeholder for title if representation's title is not applicable for some reason.
 */
- (NSString *)titlePlaceholder;

@end
