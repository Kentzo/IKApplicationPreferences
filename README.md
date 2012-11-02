Why
========================
Almost every Mac OS X application has a special preferences window,
but Apple do not provide any standard solution to build custom preferences.
We have to deal with NSWindowController/NSToolbar staff every time. Not good.

IKApplicationPreferences was developed to address this problem.

**Out of the box features:**

- Window is automatically resized to match size of the view
- Toolbar can be configured using **ASCII art**! Finally it's very easy to localize preferences.
- Toggling views are animated. On pre 10.8 it uses hide/show approach (like in Mail.app or Safari.app).
On 10.8+ it uses Core Animation (like in About This Mac introduced in Lion).
- Default window title is localized in almost every language.
- Provides methods to cyclically enumerate views. Very useful since order of preferences may depend on user's locale.
- Automatic Reference Counting (a.k.a ARC)

Requirements
========================

- Mac OS X 10.6+
- x86_64 (new runtime)

Tutorial
========================
`IKApplicationPreferences` consist of so-named Preferences Representations --- objects that adopts (formally or informally) `IKPreferencesRepresentation` protocol.

Each Preferences Representation consist of:

- view that represents preferences

- toolbar item

- *optionally* title

Therefore IKPreferencesRepresentation defines 2 required methods:

    - (NSView *)view
    - (void)configureToolbarItem:(NSToolbarItem *)anItem

and 1 optional method:

    - (NSString *)title

Most convenient (and widely used) way to create preferences representation is to subclass `NSViewController` and adopt `IKPreferencesRepresentation` for each representation.
Since NSViewController already implements both `-view` and `-title`, the only method you have to implement is `-configureToolbarItem:`.

This method receives an initialized instance of `NSToolbarItem` that it's supposed to configure. The only properties you cannot change are `target` and `action`.

It's time to create an instance of IKApplicationPreferences. As you may already noticed IKApplicationPreferences is a subclass of `NSWindowController` and it requires a nib to load the window. You may use stock *IKApplicationPreferencesWindow.xib* or you may create custom nib. See notes how to do this properly.

The designated initialized or IKApplicationPreferences is:

    - (instancetype)initWithWindowNibName:(NSString *)aNibName
                             visualFormat:(NSString *)aFormat
                          representations:(NSDictionary *)aRepresentations;

The first parameter is a name of nib we discussed above. The second and third parameters should be familiar to you if you ever worked with NSLayoutConstraint.

- **aRepresentations** is a dictionary where keys are identifiers and objects are instances of classes that adopt `IKPreferencesRepresentation`

- **aFormat** is a string which represents configuration of `NSToolbar` using ASCII art. It's essentially a comma-separated list of identifiers specified in **aRepresentations** or standard NSToolbarItem identifiers. It also supports 2 shortcuts: `' '`(NSToolbarSpaceItemIdentifier) and `'-'`(NSToolbarFlexibleSpaceItemIdentifier). E.g. `@"general,accounts, ,audio,video,-,about"`

Already done with that? Great. To show the preferences window simply use standard method of NSWindowController: `-showWindow:`.

Notes
========================

- The main reason to create custom nib is add views that will be common to any preferences. E.g. custom background or Lock/Unlock view (line in System Preferences.app). Your nib must match the following requirements:

    1. File's Owner MUST be set to `IKApplicationPreferences` or its subclass.
    2. You MUST set Owner's window to nib's window.
    3. You MUST not bind title of the window.
    4. You MUST add an *empty* view and set Owner's _representationsRootView to it.
    5. You SHOULD set _representationsRootView's autoresizing mask or constraints so it will be resized with window proportionally. It's not a requirement because you can provide custom layout in your subclass of IKApplicationPreferences.
    6. You MUST add Toolbar to the window and set its delegate to Owner.
- Default `-titlePlaceholder` uses standard CFBundleDisplayName to obtain localized name of you application. If it fails, it uses CFBundleName.
