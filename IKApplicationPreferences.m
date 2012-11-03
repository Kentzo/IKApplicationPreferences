//
//  IKApplicationPreferences.m
//  IKApplicationPreferences
//
//  Created by Ilya Kulakov on 30.10.12.
//  Copyright (c) 2012 Ilya Kulakov. All rights reserved.
//

#import "IKApplicationPreferences.h"


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
}

- (instancetype)initWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations usesCoreAnimation:(BOOL)aUsesCoreAnimation
{
    self = [self initWithWindowNibName:aNibName];

    if (self)
    {
        _toolbarItemIdentifiers = [[[self class] visualFormatByExpandingShortcuts:aFormat] componentsSeparatedByString:@","];
        _representations = [aRepresentations copy];
        _usesCoreAnimation = aUsesCoreAnimation;
    }

    return self;
}

- (instancetype)initWithWindow:(NSWindow *)window
{
    self = [super initWithWindow:window];

    if (self)
    {
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
    if (floor(NSAppKitVersionNumber) <= NSAppKitVersionNumber10_7)
        return [[self alloc] initWithWindowNibName:aNibName visualFormat:aFormat representations:aRepresentations usesCoreAnimation:NO];
    else
        return [[self alloc] initWithWindowNibName:aNibName visualFormat:aFormat representations:aRepresentations usesCoreAnimation:YES];
}

+ (NSString *)visualFormatByExpandingShortcuts:(NSString *)aFormatWithShortcuts
{
    NSMutableString *s = [aFormatWithShortcuts mutableCopy];
    [s replaceOccurrencesOfString:@" " withString:NSToolbarSpaceItemIdentifier options:0 range:NSMakeRange(0, [s length])];
    [s replaceOccurrencesOfString:@"-" withString:NSToolbarFlexibleSpaceItemIdentifier options:0 range:NSMakeRange(0, [s length])];
    return s;
}

- (NSObject<IKPreferencesRepresentation> *)representationForIdentifier:(NSString *)anIdentifier
{
    return [self.representations objectForKey:anIdentifier];
}

- (void)setSelectedRepresentationIdentifier:(NSString *)newIdentifier animated:(BOOL)isAnimated
{
    newIdentifier = [newIdentifier copy];

    if (!newIdentifier || [newIdentifier isEqual:self.selectedRepresentationIdentifier])
        return;

    NSObject<IKPreferencesRepresentation> *newRepresentation = [self representationForIdentifier:newIdentifier];

    if (!newRepresentation)
        return;

    [NSAnimationContext beginGrouping];

    [self willChangeValueForKey:@"selectedRepresentationIdentifier"];
    [self willChangeValueForKey:@"selectedRepresentation"];
    [self.window unbind:NSTitleBinding];

    newRepresentation.view.frameOrigin = NSMakePoint(0.0, 0.0);
    newRepresentation.view.autoresizingMask = NSViewMaxXMargin | NSViewMaxYMargin;

    if ([_representationsRootView wantsLayer] && isAnimated)
    {
        if (self.selectedRepresentation)
            [[_representationsRootView animator] replaceSubview:self.selectedRepresentation.view with:newRepresentation.view];
        else
            [[_representationsRootView animator] addSubview:newRepresentation.view];
    }
    else
    {
        if (self.selectedRepresentation)
            [_representationsRootView replaceSubview:self.selectedRepresentation.view with:newRepresentation.view];
        else
            [_representationsRootView addSubview:newRepresentation.view];
    }

    _selectedRepresentation = newRepresentation;
    self.window.toolbar.selectedItemIdentifier = newIdentifier;
    _selectedRepresentationIdentifier = newIdentifier;

    if ([_selectedRepresentation respondsToSelector:@selector(title)])
        [self.window bind:NSTitleBinding toObject:self withKeyPath:@"selectedRepresentation.title" options:_titleBindingOptions];

    [self didChangeValueForKey:@"selectedRepresentation"];
    [self didChangeValueForKey:@"selectedRepresentationIdentifier"];

    if (isAnimated && !_representationsRootView.wantsLayer)
        _representationsRootView.hidden = YES;

    [self adjustWindowSizeToMatchRepresentationViewSize:_selectedRepresentation.view.frame.size animated:isAnimated];

    if (isAnimated && !_representationsRootView.wantsLayer)
        _representationsRootView.hidden = NO;

    [NSAnimationContext endGrouping];

    [self.window makeFirstResponder:[newRepresentation.view nextValidKeyView]];
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
                                                                       options:NSEnumerationConcurrent
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

- (void)adjustWindowSizeToMatchRepresentationViewSize:(NSSize)newSize animated:(BOOL)isAnimated
{
    NSRect newFrame = [self windowFrameForRepresentationViewSize:newSize];

    if (_representationsRootView.wantsLayer && isAnimated)
        [self.window.animator setFrame:newFrame display:YES];
    else
        [self.window setFrame:newFrame display:YES animate:isAnimated];
}

- (void)adjustWindowAndRepresentationViewSizesToMatchRepresentationViewSize:(NSSize)newSize animated:(BOOL)isAnimated
{
    NSUInteger currentMask = self.selectedRepresentation.view.autoresizingMask;
    self.selectedRepresentation.view.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    NSRect newFrame = [self windowFrameForRepresentationViewSize:newSize];
    // MUST be blocking. Otherwise autoresizing mask will be reset before animation is complete.
    [self.window setFrame:newFrame display:YES animate:isAnimated];
    self.selectedRepresentation.view.autoresizingMask = currentMask;
}

- (NSString *)titlePlaceholder
{
    NSString *bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];

    if (!bundleName)
        bundleName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

    return [NSString stringWithFormat:NSLocalizedStringWithDefaultValue(@"%@ Preferences",
                                                                        @"IKApplicationPreferences",
                                                                        [NSBundle bundleForClass:[self class]],
                                                                        @"%@ Preferences", @"IKApplicationPreferences Default Title Placeholder Format."), bundleName];
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
        [_representationsRootView setWantsLayer:YES];

    if ([_toolbarItemIdentifiers count])
        self.selectedRepresentationIdentifier = _toolbarItemIdentifiers[0];
}

@end
