//
//  IKApplicationPreferences.m
//  IKApplicationPreferences
//
//  Created by Ilya Kulakov on 30.10.12.
//  Copyright (c) 2012 Ilya Kulakov. All rights reserved.
//

#if !__has_feature(objc_arc)
    #error IKApplicationPreferences.m MUST be compiled with ARC enabled (-fobjc-arc)
#endif


#import "IKApplicationPreferences.h"


// Used in IKApplicationPreferencesWindow
@interface _IKRepresentationRootView : NSView
@end


@implementation _IKRepresentationRootView

- (BOOL)isFlipped
{
    return YES;
}

@end


static NSString* const IKSelectedRepresentationIdentifierStateKey = @"IKSelectedRepresentationIdentifier";


@implementation IKApplicationPreferences
{
    NSArray *_toolbarItemIdentifiers;
    NSDictionary *_titleBindingOptions;
    NSView *_shownRepresentationView;
}

- (instancetype)initWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations usesCoreAnimation:(BOOL)aUsesCoreAnimation
{
    self = [self initWithWindowNibName:aNibName];

    if (self)
    {
        _toolbarItemIdentifiers = [[[self class] visualFormatByExpandingShortcuts:aFormat] componentsSeparatedByString:@","];
        _representations = [aRepresentations copy];
        _selectedRepresentationIdentifier = _toolbarItemIdentifiers[0];
        _selectedRepresentation = _representations[_selectedRepresentationIdentifier];
        _usesCoreAnimation = aUsesCoreAnimation;
    }

    return self;
}


#pragma mark Properties

+ (BOOL)automaticallyNotifiesObserversOfSelectedRepresentationIdentifier
{
    return NO;
}

+ (BOOL)automaticallyNotifiesObserversOfSelectedRepresentation
{
    return NO;
}

- (void)setSelectedRepresentationIdentifier:(NSString *)newIdentifier
{
    [self setSelectedRepresentationIdentifier:newIdentifier animated:NO];
}


#pragma mark Methods

+ (instancetype)preferencesWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations
{
    BOOL usesCoreAnimation = floor(NSAppKitVersionNumber) > NSAppKitVersionNumber10_7 && floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_8;
    return [[self alloc] initWithWindowNibName:aNibName visualFormat:aFormat representations:aRepresentations usesCoreAnimation:usesCoreAnimation];
}

+ (NSString *)visualFormatByExpandingShortcuts:(NSString *)aFormatWithShortcuts
{
    NSMutableString *s = [aFormatWithShortcuts mutableCopy];
    [s replaceOccurrencesOfString:@" " withString:NSToolbarSpaceItemIdentifier options:(NSStringCompareOptions)0 range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"-" withString:NSToolbarFlexibleSpaceItemIdentifier options:(NSStringCompareOptions)0 range:NSMakeRange(0, [s length])];
    return s;
}

- (NSObject<IKPreferencesRepresentation> *)representationForIdentifier:(NSString *)anIdentifier
{
    return [self.representations objectForKey:anIdentifier];
}

- (void)setSelectedRepresentationIdentifier:(NSString *)newIdentifier animated:(BOOL)anIsAnimated
{
    if (!newIdentifier || [newIdentifier isEqual:self.selectedRepresentationIdentifier])
        return;

    NSObject<IKPreferencesRepresentation> *newRepresentation = [self representationForIdentifier:newIdentifier];

    if (!newRepresentation)
        return;

    [self willChangeValueForKey:@"selectedRepresentationIdentifier"];
    [self willChangeValueForKey:@"selectedRepresentation"];

    _selectedRepresentationIdentifier = [newIdentifier copy];
    _selectedRepresentation = newRepresentation;

    [self didChangeValueForKey:@"selectedRepresentation"];
    [self didChangeValueForKey:@"selectedRepresentationIdentifier"];

    [self showSelectedRepresentationAnimated:anIsAnimated];
}

- (void)showSelectedRepresentationAnimated:(BOOL)anIsAnimated
{
    if (!self.isWindowLoaded)
        return;

    if (self.selectedRepresentation.view == _shownRepresentationView)
        return;

    self.window.toolbar.selectedItemIdentifier = self.selectedRepresentationIdentifier;

    NSAssert(self.selectedRepresentation.view != nil, @"Preferences Representation MUST have a view.");

    self.selectedRepresentation.view.frameOrigin = NSZeroPoint;
    self.selectedRepresentation.view.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;

    if (anIsAnimated)
    {
        if (self.usesCoreAnimation)
        {
            self.selectedRepresentation.view.alphaValue = 0.0;
            [_representationsRootView addSubview:self.selectedRepresentation.view positioned:NSWindowAbove relativeTo:_shownRepresentationView];

            // Ensure that focus ring won't be drawn for replaced view.
            [self.window makeFirstResponder:self.selectedRepresentation.view];

            [NSAnimationContext beginGrouping];
            [NSAnimationContext currentContext].duration = [self.window animationResizeTime:[self windowFrameForRepresentationViewSize:self.selectedRepresentation.view.frame.size]];

            [_shownRepresentationView.animator setAlphaValue:0.0];
            [self.selectedRepresentation.view.animator setAlphaValue:1.0];

            // Core animation is smooth, so change title immediately.
            if ([self.selectedRepresentation respondsToSelector:@selector(title)])
                [self.window bind:NSTitleBinding toObject:self.selectedRepresentation withKeyPath:@"title" options:_titleBindingOptions];

            [NSAnimationContext endGrouping];

            [self adjustWindowSizeAnimated:YES];
            [_shownRepresentationView removeFromSuperview];
            _shownRepresentationView.alphaValue = 1.0;
        }
        else
        {
            _representationsRootView.hidden = YES;

            if (_shownRepresentationView.superview == _representationsRootView)
                [_representationsRootView replaceSubview:_shownRepresentationView with:self.selectedRepresentation.view];
            else
                [_representationsRootView addSubview:self.selectedRepresentation.view];

            [self adjustWindowSizeAnimated:YES];
            _representationsRootView.hidden = NO;
        }
    }
    else
    {
        if (_shownRepresentationView.superview == _representationsRootView)
            [_representationsRootView replaceSubview:_shownRepresentationView with:self.selectedRepresentation.view];
        else
            [_representationsRootView addSubview:self.selectedRepresentation.view];

        [self adjustWindowSizeAnimated:NO];
    }

    _shownRepresentationView = self.selectedRepresentation.view;

    if ([self.selectedRepresentation respondsToSelector:@selector(title)])
        [self.window bind:NSTitleBinding toObject:self.selectedRepresentation withKeyPath:@"title" options:_titleBindingOptions];

    [self.window makeFirstResponder:[self.selectedRepresentation.view nextValidKeyView]];
}

- (void)showNextRepresentationAnimated:(BOOL)isAnimated
{
    if ([_toolbarItemIdentifiers count] == 0)
        return;

    NSUInteger currentIndex = [_toolbarItemIdentifiers indexOfObject:self.selectedRepresentationIdentifier];

    if (currentIndex == NSNotFound)
        return;

    NSUInteger nextIndex = [_toolbarItemIdentifiers indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(currentIndex + 1, [_toolbarItemIdentifiers count] - (currentIndex + 1))]
                                                                   options:NSEnumerationConcurrent
                                                               passingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop) {
                                                                   return ![obj isEqual:NSToolbarSpaceItemIdentifier] && ![obj isEqual:NSToolbarFlexibleSpaceItemIdentifier];
                                                               }];

    if (nextIndex != NSNotFound)
        [self setSelectedRepresentationIdentifier:_toolbarItemIdentifiers[nextIndex] animated:isAnimated];
    else
        [self setSelectedRepresentationIdentifier:_toolbarItemIdentifiers[0] animated:isAnimated];
}

- (void)showPreviousRepresentationAnimated:(BOOL)isAnimated
{
    if ([_toolbarItemIdentifiers count] == 0)
        return;

    NSUInteger currentIndex = [_toolbarItemIdentifiers indexOfObject:self.selectedRepresentationIdentifier];

    if (currentIndex == NSNotFound)
        return;

    NSUInteger previousIndex = [_toolbarItemIdentifiers indexOfObjectAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, currentIndex)]
                                                                       options:NSEnumerationConcurrent | NSEnumerationReverse
                                                                   passingTest:^BOOL(NSString *obj, NSUInteger idx, BOOL *stop) {
                                                                       return ![obj isEqual:NSToolbarSpaceItemIdentifier] && ![obj isEqual:NSToolbarFlexibleSpaceItemIdentifier];
                                                                   }];

    if (previousIndex != NSNotFound)
        [self setSelectedRepresentationIdentifier:_toolbarItemIdentifiers[previousIndex] animated:isAnimated];
    else
        [self setSelectedRepresentationIdentifier:[_toolbarItemIdentifiers lastObject] animated:isAnimated];
}

- (void)toggleRepresentationForToolbarItem:(NSToolbarItem *)anItem
{
    [self setSelectedRepresentationIdentifier:anItem.itemIdentifier animated:YES];
}

- (NSRect)windowFrameForRepresentationViewSize:(NSSize)aRepresentationViewSize
{
    // Assume that spaces between edges of _representationsRootView and the window are never changed.
    // Therefore the difference between _representationsRootView and aRepresentationViewSize
    // can be applied to adjust size of the window.

    NSSize oldSize = _representationsRootView.frame.size;
    NSSize newSize = aRepresentationViewSize;

    if (NSEqualSizes(oldSize, newSize))
        return self.window.frame;

    NSRect oldFrame = self.window.frame;
    NSRect newFrame = NSMakeRect(oldFrame.origin.x,
                                 0.0,
                                 MIN(self.window.contentMaxSize.width, MAX(self.window.contentMinSize.width, oldFrame.size.width + (newSize.width - oldSize.width))),
                                 MIN(self.window.contentMaxSize.height, MAX(self.window.contentMinSize.height, oldFrame.size.height + (newSize.height - oldSize.height))));
    newFrame.origin.y = oldFrame.origin.y - (newFrame.size.height - oldFrame.size.height);

    return newFrame;
}

- (void)adjustWindowSizeAnimated:(BOOL)anIsAnimated
{
    if (!self.isWindowLoaded)
        return;

    NSRect newFrame = [self windowFrameForRepresentationViewSize:self.selectedRepresentation.view.frame.size];
    [self.window setFrame:newFrame display:YES animate:anIsAnimated];
}

- (void)setSelectedRepresentationViewSize:(NSSize)newSize animated:(BOOL)anIsAnimated
{
    NSUInteger currentMask = self.selectedRepresentation.view.autoresizingMask;
    self.selectedRepresentation.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    NSRect newFrame = [self windowFrameForRepresentationViewSize:newSize];
    [self.window setFrame:newFrame display:YES animate:anIsAnimated];
    self.selectedRepresentation.view.autoresizingMask = currentMask;
}

- (NSString *)titlePlaceholder
{
    NSString *appName = [[NSRunningApplication currentApplication] localizedName];

    return [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"%@ Preferences",
                                                                        @"IKApplicationPreferences",
                                                                        [NSBundle bundleForClass:[self class]],
                                                                        @"%@ Preferences", @"IKApplicationPreferences Default Title Placeholder Format."),
                     appName];
}


#pragma mark NSWindowDelegate

- (void)window:(NSWindow *)aWindow willEncodeRestorableState:(NSCoder *)aState
{
    if (aWindow != self.window)
        return;

    [aState encodeObject:self.selectedRepresentationIdentifier forKey:IKSelectedRepresentationIdentifierStateKey];
}

- (void)window:(NSWindow *)aWindow didDecodeRestorableState:(NSCoder *)aState
{
    if (aWindow != self.window)
        return;

    NSString *selectedIdentifier = [aState decodeObjectForKey:IKSelectedRepresentationIdentifierStateKey];

    if ([selectedIdentifier isKindOfClass:[NSString class]] &&
        [_toolbarItemIdentifiers containsObject:selectedIdentifier])
    {
        self.selectedRepresentationIdentifier = selectedIdentifier;
    }
}


#pragma mark NSToolbarDelegate

- (NSToolbarItem *)toolbar:(NSToolbar *)aToolbar itemForItemIdentifier:(NSString *)anItemIdentifier willBeInsertedIntoToolbar:(BOOL)aFlag
{
    NSObject<IKPreferencesRepresentation> *representation = [self representationForIdentifier:anItemIdentifier];

    if (!representation)
        return nil;

    NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:anItemIdentifier];
    [representation configureToolbarItem:item];
    item.target = self;
    item.action = @selector(toggleRepresentationForToolbarItem:);
    return item;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)aToolbar
{
    return _toolbarItemIdentifiers;
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)aToolbar
{
    return _toolbarItemIdentifiers;
}

- (NSArray *)toolbarSelectableItemIdentifiers:(NSToolbar *)aToolbar
{
    return _toolbarItemIdentifiers;
}


#pragma mark NSWindowController

- (void)windowDidLoad
{
    [super windowDidLoad];

    NSAssert(_representationsRootView != nil, @"You MUST set _representationsRootView in your custom template.");

    NSString *titleBindingPlaceholder = [self titlePlaceholder];
    _titleBindingOptions = @{
        NSRaisesForNotApplicableKeysBindingOption : @(NO),
        NSMultipleValuesPlaceholderBindingOption : titleBindingPlaceholder,
        NSNoSelectionPlaceholderBindingOption : titleBindingPlaceholder,
        NSNotApplicablePlaceholderBindingOption : titleBindingPlaceholder,
        NSNullPlaceholderBindingOption : titleBindingPlaceholder
    };

    if (self.usesCoreAnimation)
        _representationsRootView.wantsLayer = YES;

    [self showSelectedRepresentationAnimated:NO];
}


#pragma mark NSResponder

- (void)cancel:(id)aSender
{
    [self.window performClose:aSender];
}

@end
