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


@implementation IKApplicationPreferences
{
    NSArray *_toolbarItemIdentifiers;
    NSDictionary *_titleBindingOptions;
}

- (instancetype)initWithWindowNibName:(NSString *)aNibName visualFormat:(NSString *)aFormat representations:(NSDictionary *)aRepresentations
{
    self = [self initWithWindowNibName:aNibName];
    
    if (self)
    {
        _toolbarItemIdentifiers = [[[self class] visualFormatByExpandingShortcuts:aFormat] componentsSeparatedByString:@","];
        _representations = [aRepresentations copy];
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

- (void)dealloc
{
}


#pragma mark Properties

+ (BOOL)automaticallyNotifiesObserversOfSelectedRepresentationIndex
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
    if (!newIdentifier || [newIdentifier isEqual:self.selectedRepresentationIdentifier])
        return;
    
    NSObject<IKPreferencesRepresentation> *newRepresentation = [self representationForIdentifier:newIdentifier];
    
    if (!newRepresentation)
        return;
    
    [NSAnimationContext beginGrouping];
    
    [self willChangeValueForKey:@"selectedRepresentationIndex"];
    [self willChangeValueForKey:@"selectedRepresentation"];
    

    NSSize viewSize = newRepresentation.view.frame.size;
    [newRepresentation.view setFrame:NSMakeRect(0, 0, viewSize.width, viewSize.height)];
    
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
    
    self.window.toolbar.selectedItemIdentifier = newIdentifier;
    
    [self.window unbind:NSTitleBinding];
    
    _selectedRepresentation = newRepresentation;
    
    if ([_selectedRepresentation respondsToSelector:@selector(title)])
        [self.window bind:NSTitleBinding toObject:self withKeyPath:@"selectedRepresentation.title" options:_titleBindingOptions];
    
    [self didChangeValueForKey:@"selectedRepresentation"];
    [self didChangeValueForKey:@"selectedRepresentationIndex"];
    
    if (isAnimated && !_representationsRootView.wantsLayer)
        _representationsRootView.hidden = YES;
    
    [self adjustWindowSizeAnimated:isAnimated];
    
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

- (void)adjustWindowSizeAnimated:(BOOL)isAnimated
{
    NSSize oldSize = [_representationsRootView frame].size;
    NSSize newSize = self.selectedRepresentation.view.frame.size;
    
    if (NSEqualSizes(oldSize, newSize))
        return;
    
    NSRect oldFrame = self.window.frame;
    NSRect newFrame = NSMakeRect(oldFrame.origin.x,
                                 0.0,
                                 MIN(self.window.contentMaxSize.width, MAX(self.window.contentMinSize.width, oldFrame.size.width + (newSize.width - oldSize.width))),
                                 MIN(self.window.contentMaxSize.height, MAX(self.window.contentMinSize.height, oldFrame.size.height + (newSize.height - oldSize.height))));
    newFrame.origin.y = oldFrame.origin.y - (newFrame.size.height - oldFrame.size.height);
    
    if ([_representationsRootView wantsLayer] && isAnimated)
        [self.window.animator setFrame:newFrame display:YES];
    else
        [self.window setFrame:newFrame display:YES animate:YES];
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
    
    if ([_toolbarItemIdentifiers count])
        self.selectedRepresentationIdentifier = _toolbarItemIdentifiers[0];
}

@end
