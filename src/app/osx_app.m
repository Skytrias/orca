//*****************************************************************
//
//	$file: osx_app.m $
//	$author: Martin Fouilleul $
//	$date: 16/05/2020 $
//	$revision: $
//	$note: (C) 2020 by Martin Fouilleul - all rights reserved $
//
//*****************************************************************

#import <QuartzCore/QuartzCore.h> //CATransaction

#include <stdlib.h> // malloc/free

#include "graphics/graphics_surface.h"
#include "lists.h"
#include "macros.h"
#include "memory.h"
#include "platform_clock.h"
#include "platform_debug.h"
#include "ringbuffer.h"

#include "app.c"

//--------------------------------------------------------------------
// mp window struct and utility functions
//--------------------------------------------------------------------

static u32 oc_osx_get_window_style_mask(oc_window_style style)
{
    u32 mask = 0;
    if(style & OC_WINDOW_STYLE_NO_TITLE)
    {
        mask = NSWindowStyleMaskBorderless;
    }
    else
    {
        mask = NSWindowStyleMaskTitled;
    }

    if(!(style & OC_WINDOW_STYLE_FIXED_SIZE))
    {
        mask |= NSWindowStyleMaskResizable;
    }
    if(!(style & OC_WINDOW_STYLE_NO_CLOSE))
    {
        mask |= NSWindowStyleMaskClosable;
    }
    if(!(style & OC_WINDOW_STYLE_NO_MINIFY))
    {
        mask |= NSWindowStyleMaskMiniaturizable;
    }
    return (mask);
}

//---------------------------------------------------------------

static void oc_init_osx_keys()
{
    memset(oc_appData.keyCodes, OC_KEY_UNKNOWN, 256 * sizeof(int));

    oc_appData.keyCodes[0x1D] = OC_KEY_0;
    oc_appData.keyCodes[0x12] = OC_KEY_1;
    oc_appData.keyCodes[0x13] = OC_KEY_2;
    oc_appData.keyCodes[0x14] = OC_KEY_3;
    oc_appData.keyCodes[0x15] = OC_KEY_4;
    oc_appData.keyCodes[0x17] = OC_KEY_5;
    oc_appData.keyCodes[0x16] = OC_KEY_6;
    oc_appData.keyCodes[0x1A] = OC_KEY_7;
    oc_appData.keyCodes[0x1C] = OC_KEY_8;
    oc_appData.keyCodes[0x19] = OC_KEY_9;
    oc_appData.keyCodes[0x00] = OC_KEY_A;
    oc_appData.keyCodes[0x0B] = OC_KEY_B;
    oc_appData.keyCodes[0x08] = OC_KEY_C;
    oc_appData.keyCodes[0x02] = OC_KEY_D;
    oc_appData.keyCodes[0x0E] = OC_KEY_E;
    oc_appData.keyCodes[0x03] = OC_KEY_F;
    oc_appData.keyCodes[0x05] = OC_KEY_G;
    oc_appData.keyCodes[0x04] = OC_KEY_H;
    oc_appData.keyCodes[0x22] = OC_KEY_I;
    oc_appData.keyCodes[0x26] = OC_KEY_J;
    oc_appData.keyCodes[0x28] = OC_KEY_K;
    oc_appData.keyCodes[0x25] = OC_KEY_L;
    oc_appData.keyCodes[0x2E] = OC_KEY_M;
    oc_appData.keyCodes[0x2D] = OC_KEY_N;
    oc_appData.keyCodes[0x1F] = OC_KEY_O;
    oc_appData.keyCodes[0x23] = OC_KEY_P;
    oc_appData.keyCodes[0x0C] = OC_KEY_Q;
    oc_appData.keyCodes[0x0F] = OC_KEY_R;
    oc_appData.keyCodes[0x01] = OC_KEY_S;
    oc_appData.keyCodes[0x11] = OC_KEY_T;
    oc_appData.keyCodes[0x20] = OC_KEY_U;
    oc_appData.keyCodes[0x09] = OC_KEY_V;
    oc_appData.keyCodes[0x0D] = OC_KEY_W;
    oc_appData.keyCodes[0x07] = OC_KEY_X;
    oc_appData.keyCodes[0x10] = OC_KEY_Y;
    oc_appData.keyCodes[0x06] = OC_KEY_Z;

    oc_appData.keyCodes[0x27] = OC_KEY_APOSTROPHE;
    oc_appData.keyCodes[0x2A] = OC_KEY_BACKSLASH;
    oc_appData.keyCodes[0x2B] = OC_KEY_COMMA;
    oc_appData.keyCodes[0x18] = OC_KEY_EQUAL;
    oc_appData.keyCodes[0x32] = OC_KEY_GRAVE_ACCENT;
    oc_appData.keyCodes[0x21] = OC_KEY_LEFT_BRACKET;
    oc_appData.keyCodes[0x1B] = OC_KEY_MINUS;
    oc_appData.keyCodes[0x2F] = OC_KEY_PERIOD;
    oc_appData.keyCodes[0x1E] = OC_KEY_RIGHT_BRACKET;
    oc_appData.keyCodes[0x29] = OC_KEY_SEMICOLON;
    oc_appData.keyCodes[0x2C] = OC_KEY_SLASH;
    oc_appData.keyCodes[0x0A] = OC_KEY_WORLD_1;

    oc_appData.keyCodes[0x33] = OC_KEY_BACKSPACE;
    oc_appData.keyCodes[0x39] = OC_KEY_CAPS_LOCK;
    oc_appData.keyCodes[0x75] = OC_KEY_DELETE;
    oc_appData.keyCodes[0x7D] = OC_KEY_DOWN;
    oc_appData.keyCodes[0x77] = OC_KEY_END;
    oc_appData.keyCodes[0x24] = OC_KEY_ENTER;
    oc_appData.keyCodes[0x35] = OC_KEY_ESCAPE;
    oc_appData.keyCodes[0x7A] = OC_KEY_F1;
    oc_appData.keyCodes[0x78] = OC_KEY_F2;
    oc_appData.keyCodes[0x63] = OC_KEY_F3;
    oc_appData.keyCodes[0x76] = OC_KEY_F4;
    oc_appData.keyCodes[0x60] = OC_KEY_F5;
    oc_appData.keyCodes[0x61] = OC_KEY_F6;
    oc_appData.keyCodes[0x62] = OC_KEY_F7;
    oc_appData.keyCodes[0x64] = OC_KEY_F8;
    oc_appData.keyCodes[0x65] = OC_KEY_F9;
    oc_appData.keyCodes[0x6D] = OC_KEY_F10;
    oc_appData.keyCodes[0x67] = OC_KEY_F11;
    oc_appData.keyCodes[0x6F] = OC_KEY_F12;
    oc_appData.keyCodes[0x69] = OC_KEY_F13;
    oc_appData.keyCodes[0x6B] = OC_KEY_F14;
    oc_appData.keyCodes[0x71] = OC_KEY_F15;
    oc_appData.keyCodes[0x6A] = OC_KEY_F16;
    oc_appData.keyCodes[0x40] = OC_KEY_F17;
    oc_appData.keyCodes[0x4F] = OC_KEY_F18;
    oc_appData.keyCodes[0x50] = OC_KEY_F19;
    oc_appData.keyCodes[0x5A] = OC_KEY_F20;
    oc_appData.keyCodes[0x73] = OC_KEY_HOME;
    oc_appData.keyCodes[0x72] = OC_KEY_INSERT;
    oc_appData.keyCodes[0x7B] = OC_KEY_LEFT;
    oc_appData.keyCodes[0x3A] = OC_KEY_LEFT_ALT;
    oc_appData.keyCodes[0x3B] = OC_KEY_LEFT_CONTROL;
    oc_appData.keyCodes[0x38] = OC_KEY_LEFT_SHIFT;
    oc_appData.keyCodes[0x37] = OC_KEY_LEFT_SUPER;
    oc_appData.keyCodes[0x6E] = OC_KEY_MENU;
    oc_appData.keyCodes[0x47] = OC_KEY_NUM_LOCK;
    oc_appData.keyCodes[0x79] = OC_KEY_PAGE_DOWN;
    oc_appData.keyCodes[0x74] = OC_KEY_PAGE_UP;
    oc_appData.keyCodes[0x7C] = OC_KEY_RIGHT;
    oc_appData.keyCodes[0x3D] = OC_KEY_RIGHT_ALT;
    oc_appData.keyCodes[0x3E] = OC_KEY_RIGHT_CONTROL;
    oc_appData.keyCodes[0x3C] = OC_KEY_RIGHT_SHIFT;
    oc_appData.keyCodes[0x36] = OC_KEY_RIGHT_SUPER;
    oc_appData.keyCodes[0x31] = OC_KEY_SPACE;
    oc_appData.keyCodes[0x30] = OC_KEY_TAB;
    oc_appData.keyCodes[0x7E] = OC_KEY_UP;

    oc_appData.keyCodes[0x52] = OC_KEY_KP_0;
    oc_appData.keyCodes[0x53] = OC_KEY_KP_1;
    oc_appData.keyCodes[0x54] = OC_KEY_KP_2;
    oc_appData.keyCodes[0x55] = OC_KEY_KP_3;
    oc_appData.keyCodes[0x56] = OC_KEY_KP_4;
    oc_appData.keyCodes[0x57] = OC_KEY_KP_5;
    oc_appData.keyCodes[0x58] = OC_KEY_KP_6;
    oc_appData.keyCodes[0x59] = OC_KEY_KP_7;
    oc_appData.keyCodes[0x5B] = OC_KEY_KP_8;
    oc_appData.keyCodes[0x5C] = OC_KEY_KP_9;
    oc_appData.keyCodes[0x45] = OC_KEY_KP_ADD;
    oc_appData.keyCodes[0x41] = OC_KEY_KP_DECIMAL;
    oc_appData.keyCodes[0x4B] = OC_KEY_KP_DIVIDE;
    oc_appData.keyCodes[0x4C] = OC_KEY_KP_ENTER;
    oc_appData.keyCodes[0x51] = OC_KEY_KP_EQUAL;
    oc_appData.keyCodes[0x43] = OC_KEY_KP_MULTIPLY;
    oc_appData.keyCodes[0x4E] = OC_KEY_KP_SUBTRACT;

    memset(oc_appData.nativeKeys, 0, sizeof(int) * OC_KEY_COUNT);
    for(int nativeKey = 0; nativeKey < 256; nativeKey++)
    {
        oc_key_code mpKey = oc_appData.keyCodes[nativeKey];
        if(mpKey)
        {
            oc_appData.nativeKeys[mpKey] = nativeKey;
        }
    }
}

static int oc_convert_osx_key(unsigned short nsCode)
{
    if(nsCode >= 265)
    {
        return (OC_KEY_UNKNOWN);
    }
    else
    {
        return (oc_appData.keyCodes[nsCode]);
    }
}

static oc_keymod_flags oc_convert_osx_mods(NSUInteger nsFlags)
{
    oc_keymod_flags mods = OC_KEYMOD_NONE;
    if(nsFlags & NSEventModifierFlagShift)
    {
        mods |= OC_KEYMOD_SHIFT;
    }
    if(nsFlags & NSEventModifierFlagControl)
    {
        mods |= OC_KEYMOD_CTRL;
    }
    if(nsFlags & NSEventModifierFlagOption)
    {
        mods |= OC_KEYMOD_ALT;
    }
    if(nsFlags & NSEventModifierFlagCommand)
    {
        mods |= OC_KEYMOD_CMD;
    }
    return (mods);
}

static void oc_update_keyboard_layout()
{
    if(oc_appData.osx.kbLayoutInputSource)
    {
        CFRelease(oc_appData.osx.kbLayoutInputSource);
        oc_appData.osx.kbLayoutInputSource = 0;
        oc_appData.osx.kbLayoutUnicodeData = nil;
    }

    oc_appData.osx.kbLayoutInputSource = TISCopyCurrentKeyboardLayoutInputSource();
    if(!oc_appData.osx.kbLayoutInputSource)
    {
        oc_log_error("Failed to load keyboard layout input source");
    }

    oc_appData.osx.kbLayoutUnicodeData = TISGetInputSourceProperty(oc_appData.osx.kbLayoutInputSource,
                                                                   kTISPropertyUnicodeKeyLayoutData);
    if(!oc_appData.osx.kbLayoutUnicodeData)
    {
        oc_log_error("Failed to load keyboard layout unicode data");
    }

    memset(oc_appData.keyLabels, 0, sizeof(oc_key_utf8) * OC_KEY_COUNT);

    for(int key = 0; key < OC_KEY_COUNT; key++)
    {
        //TODO: check that the key is printable
        int nativeKey = oc_appData.nativeKeys[key];

        UInt32 deadKeyState = 0;
        UniChar characters[4];
        UniCharCount characterCount = 0;

        if(UCKeyTranslate((UCKeyboardLayout*)[(NSData*)oc_appData.osx.kbLayoutUnicodeData bytes],
                          nativeKey,
                          kUCKeyActionDisplay,
                          0,
                          LMGetKbdType(),
                          kUCKeyTranslateNoDeadKeysBit,
                          &deadKeyState,
                          sizeof(characters) / sizeof(UniChar),
                          &characterCount,
                          characters)
           != noErr)
        {
            oc_appData.keyLabels[key].labelLen = 0;
        }
        else
        {
            NSString* nsString = [[NSString alloc] initWithCharacters:characters length:characterCount];
            const char* cstring = [nsString UTF8String];
            u32 len = strlen(cstring);
            oc_appData.keyLabels[key].labelLen = oc_min(len, 8);
            memcpy(oc_appData.keyLabels[key].label, cstring, oc_appData.keyLabels[key].labelLen);
        }
    }
}

oc_str8 oc_key_to_label(oc_key_code key)
{
    oc_key_utf8* keyInfo = &(oc_appData.keyLabels[key]);
    oc_str8 label = oc_str8_from_buffer(keyInfo->labelLen, keyInfo->label);
    return (label);
}

oc_key_code oc_label_to_key(oc_str8 label)
{
    oc_key_code res = OC_KEY_UNKNOWN;
    for(int key = 0; key < OC_KEY_COUNT; key++)
    {
        oc_str8 keyLabel = oc_key_to_label(key);
        if(keyLabel.len == label.len
           && !strncmp(keyLabel.ptr, label.ptr, label.len))
        {
            res = key;
            break;
        }
    }
    return (res);
}

@interface OCWindow : NSWindow
{
    oc_window_data* mpWindow;
}
- (id)initWithWindowData:(oc_window_data*)window contentRect:(NSRect)rect styleMask:(uint32)style;
@end

@interface OCKeyboardLayoutListener : NSObject
@end

@implementation OCKeyboardLayoutListener

- (void)selectedKeyboardInputSourceChanged:(NSObject*)object
{
    oc_update_keyboard_layout();
}

@end

void oc_install_keyboard_layout_listener()
{
    oc_appData.osx.kbLayoutListener = [[OCKeyboardLayoutListener alloc] init];
    [[NSDistributedNotificationCenter defaultCenter]
        addObserver:oc_appData.osx.kbLayoutListener
           selector:@selector(selectedKeyboardInputSourceChanged:)
               name:(__bridge NSString*)kTISNotifySelectedKeyboardInputSourceChanged
             object:nil];
}

//---------------------------------------------------------------
// Application and app delegate
//---------------------------------------------------------------

@interface OCApplication : NSApplication
@end

@implementation OCApplication

- (void)noOpThread:(id)object
{
}

//This is necessary in order to receive keyUp events when we have a key combination with Cmd.
- (void)sendEvent:(NSEvent*)event
{
    if([event type] == NSEventTypeKeyUp && ([event modifierFlags] & NSEventModifierFlagCommand))
        [[self keyWindow] sendEvent:event];
    else
        [super sendEvent:event];
}

@end

@interface OCAppDelegate : NSObject <NSApplicationDelegate>
- (id)init;
@end

@implementation OCAppDelegate

- (id)init
{
    self = [super init];
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleAppleEvent:withReplyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];

    return (self);
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication*)sender
{
    //NOTE: We set shouldQuit to true and send a Quit event
    //	We then return a value to cancel the direct termination because we still
    //	want to execte the code after oc_event_loop(). If the user didn't set shouldQuit to
    //	false, oc_event_loop() will exit, and the user can execute any cleanup needed and
    //	exit the program.

    oc_appData.shouldQuit = true;
    oc_event event = {};
    event.type = OC_EVENT_QUIT;
    oc_queue_event(&event);

    return (NSTerminateCancel);
}

- (void)applicationWillFinishLaunching:(NSNotification*)notification
{
    @autoreleasepool
    {

        //NOTE(martin): add a menu for quit, and a corresponding key equivalent.
        //		this allows to quit the application when there is no window
        //		left to catch our Cmd-Q key equivalent
        NSMenu* bar = [[NSMenu alloc] init];
        [NSApp setMainMenu:bar];

        NSMenuItem* appMenuItem =
            [bar addItemWithTitle:@""
                           action:NULL
                    keyEquivalent:@""];
        NSMenu* appMenu = [[NSMenu alloc] init];
        [appMenuItem setSubmenu:appMenu];

        [appMenu addItemWithTitle:@"Quit"
                           action:@selector(terminate:)
                    keyEquivalent:@"q"];
    }
}

- (void)timerElapsed:(NSTimer*)timer
{
    oc_event event = {};
    event.type = OC_EVENT_FRAME;
    oc_queue_event(&event);
}

- (void)applicationDidFinishLaunching:(NSNotification*)notification
{
    @autoreleasepool
    {
        //WARN(martin): the order of these calls seem to matter a lot for properly showing the menu bar
        //              with other orderings, the menu doesn't display before the application is put out of
        //              focus and on focus again... This is flaky undocumented behaviour, so although it is
        //		fixed by the current ordering, we expect the problem to show up again in future
        //		versions of macOS.

        //NOTE(martin): send a dummy event to wake-up the run loop and exit from the run loop.

        NSEvent* event = [NSEvent otherEventWithType:NSEventTypeApplicationDefined
                                            location:NSMakePoint(0, 0)
                                       modifierFlags:0
                                           timestamp:0
                                        windowNumber:0
                                             context:nil
                                             subtype:0
                                               data1:0
                                               data2:0];

        [NSApp postEvent:event atStart:YES];
        [NSApp stop:nil];
    }
}

- (BOOL)application:(NSApplication*)application openFile:(NSString*)filename
{
    oc_event event = { 0 };
    event.window = (oc_window){ 0 };
    event.type = OC_EVENT_PATHDROP;

    oc_arena* scratch = oc_scratch();
    oc_arena_scope scope = oc_arena_scope_begin(scratch);

    oc_str8 path = oc_str8_push_cstring(scratch, [filename UTF8String]);
    oc_str8_list_push(scratch, &event.paths, path);

    oc_queue_event(&event);

    oc_arena_scope_end(scope);

    return (YES);
}

- (void)handleAppleEvent:(NSAppleEventDescriptor*)appleEvent withReplyEvent:(NSAppleEventDescriptor*)replyEvent
{
    NSString* nsPath = [[appleEvent paramDescriptorForKeyword:keyDirectObject] stringValue];

    oc_event event = {};
    event.window = (oc_window){ 0 };
    event.type = OC_EVENT_PATHDROP;

    oc_arena* scratch = oc_scratch();
    oc_arena_scope scope = oc_arena_scope_begin(scratch);

    oc_str8 path = oc_str8_push_cstring(scratch, [nsPath UTF8String]);
    oc_str8_list_push(scratch, &event.paths, path);

    oc_queue_event(&event);

    oc_arena_scope_end(scope);
}

//TODO: drag and drop paths

@end // @implementation OCAppDelegate

//---------------------------------------------------------------
// Custom NSWindow
//---------------------------------------------------------------

@implementation OCWindow

- (id)initWithWindowData:(oc_window_data*)window contentRect:(NSRect)rect styleMask:(uint32)style
{
    mpWindow = window;
    return ([self initWithContentRect:rect styleMask:style backing:NSBackingStoreBuffered defer:NO]);
}

- (BOOL)canBecomeKeyWindow
{
    return (!(mpWindow->style & OC_WINDOW_STYLE_NO_FOCUS));
}

/*
- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if([sender draggingSourceOperationMask] & NSDragOperationGeneric)
	{
		return NSDragOperationGeneric;
	}
	return NSDragOperationNone;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{@autoreleasepool
{
	NSPasteboard *pasteboard = [sender draggingPasteboard];
	NSArray *types = [NSArray arrayWithObject:NSFilenamesPboardType];
	NSString *desiredType = [pasteboard availableTypeFromArray:types];

	NSData *data;
	NSArray *array;
	NSPoint point;

	if (desiredType == nil) {
    	return NO;
	}

	data = [pasteboard dataForType:desiredType];
	if (data == nil) {
    	return NO;
	}

	SDL_assert([desiredType isEqualToString:NSFilenamesPboardType]);
	array = [pasteboard propertyListForType:@"NSFilenamesPboardType"];

	// Code addon to update the mouse location
	point = [sender draggingLocation];
	mouse = SDL_GetMouse();
	x = (int)point.x;
	y = (int)(sdlwindow->h - point.y);
	if (x >= 0 && x < sdlwindow->w && y >= 0 && y < sdlwindow->h) {
    	SDL_SendMouseMotion(sdlwindow, mouse->mouseID, 0, x, y);
	}
	// Code addon to update the mouse location

	for (NSString *path in array) {
    	NSURL *fileURL = [NSURL fileURLWithPath:path];
    	NSNumber *isAlias = nil;

    	[fileURL getResourceValue:&isAlias forKey:NSURLIsAliasFileKey error:nil];

    	// If the URL is an alias, resolve it.
    	if ([isAlias boolValue]) {
        	NSURLBookmarkResolutionOptions opts = NSURLBookmarkResolutionWithoutMounting | NSURLBookmarkResolutionWithoutUI;
        	NSData *bookmark = [NSURL bookmarkDataWithContentsOfURL:fileURL error:nil];
        	if (bookmark != nil) {
            	NSURL *resolvedURL = [NSURL URLByResolvingBookmarkData:bookmark
                                                           	options:opts
                                                     	relativeToURL:nil
                                               	bookmarkDataIsStale:nil
                                                             	error:nil];

            	if (resolvedURL != nil) {
                	fileURL = resolvedURL;
            	}
        	}
    	}

    	if (!SDL_SendDropFile(sdlwindow, [[fileURL path] UTF8String])) {
        	return NO;
    	}
	}

	SDL_SendDropComplete(sdlwindow);
	return YES;
}

- (BOOL)wantsPeriodicDraggingUpdates;
- (BOOL)validateMenuItem:(NSMenuItem *)menuItem;
*/

@end //@implementation OCWindow

//---------------------------------------------------------------
// Custom NSWindow delegate
//---------------------------------------------------------------

@interface OCWindowDelegate : NSObject
{
    oc_window_data* mpWindow;
}
- (id)initWithWindowData:(oc_window_data*)window;
@end

@implementation OCWindowDelegate

- (id)initWithWindowData:(oc_window_data*)window
{
    self = [super init];
    if(self != nil)
    {
        mpWindow = window;
    }
    return (self);
}

- (void)windowDidBecomeKey:(NSNotification*)notification
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(mpWindow);
    event.type = OC_EVENT_WINDOW_FOCUS;

    mpWindow->hidden = false;

    oc_queue_event(&event);
}

- (void)windowDidResignKey:(NSNotification*)notification
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(mpWindow);
    event.type = OC_EVENT_WINDOW_UNFOCUS;

    oc_queue_event(&event);
}

- (void)windowDidMove:(NSNotification*)notification
{
    const NSRect contentRect = [[mpWindow->osx.nsWindow contentView] frame];
    const NSRect frameRect = [mpWindow->osx.nsWindow frame];
    NSScreen* screen = mpWindow->osx.nsWindow.screen;

    oc_event event = {};
    event.window = oc_window_handle_from_ptr(mpWindow);
    event.type = OC_EVENT_WINDOW_MOVE;

    event.move.frame.x = frameRect.origin.x;
    event.move.frame.y = screen.frame.size.height - frameRect.origin.y - frameRect.size.height;
    event.move.frame.w = frameRect.size.width;
    event.move.frame.h = frameRect.size.height;

    event.move.content.x = frameRect.origin.x + contentRect.origin.x;
    event.move.content.y = screen.frame.size.height - frameRect.origin.y - contentRect.origin.y - contentRect.size.height;
    event.move.content.w = contentRect.size.width;
    event.move.content.h = contentRect.size.height;

    oc_queue_event(&event);
}

- (void)windowDidResize:(NSNotification*)notification
{
    const NSRect contentRect = [[mpWindow->osx.nsWindow contentView] frame];
    const NSRect frameRect = [mpWindow->osx.nsWindow frame];
    NSScreen* screen = mpWindow->osx.nsWindow.screen;

    oc_event event = {};
    event.window = oc_window_handle_from_ptr(mpWindow);
    event.type = OC_EVENT_WINDOW_RESIZE;

    event.move.frame.x = frameRect.origin.x;
    event.move.frame.y = screen.frame.size.height - frameRect.origin.y - frameRect.size.height;
    event.move.frame.w = frameRect.size.width;
    event.move.frame.h = frameRect.size.height;

    event.move.content.x = frameRect.origin.x + contentRect.origin.x;
    event.move.content.y = screen.frame.size.height - frameRect.origin.y - contentRect.origin.y - contentRect.size.height;
    event.move.content.w = contentRect.size.width;
    event.move.content.h = contentRect.size.height;

    if(oc_appData.liveResizeCallback)
    {
        oc_appData.liveResizeCallback(event, oc_appData.liveResizeData);
    }

    //TODO: also ensure we don't overflow the queue during live resize...
    oc_queue_event(&event);
}

- (void)windowWillStartLiveResize:(NSNotification*)notification
{
    //TODO
}

- (void)windowDidEndLiveResize:(NSNotification*)notification
{
    //TODO
}

- (void)windowWillClose:(NSNotification*)notification
{
    mpWindow->osx.nsWindow = nil;
    [mpWindow->osx.nsView release];
    mpWindow->osx.nsView = nil;
    [mpWindow->osx.nsWindowDelegate release];
    mpWindow->osx.nsWindowDelegate = nil;

    oc_window_recycle_ptr(mpWindow);
}

- (BOOL)windowShouldClose:(id)sender
{
    mpWindow->shouldClose = true;

    oc_event event = {};
    event.window = oc_window_handle_from_ptr(mpWindow);
    event.type = OC_EVENT_WINDOW_CLOSE;

    oc_queue_event(&event);

    return (mpWindow->shouldClose);
}

@end //@implementation OCWindowDelegate

//---------------------------------------------------------------
// Custom NSView
//---------------------------------------------------------------

@interface OCView : NSView <NSTextInputClient>
{
    oc_window_data* window;
    NSTrackingArea* trackingArea;
    NSMutableAttributedString* markedText;
}
- (id)initWithWindowData:(oc_window_data*)mpWindow;
@end

@implementation OCView

- (id)initWithWindowData:(oc_window_data*)mpWindow
{
    self = [super init];
    if(self != nil)
    {
        window = mpWindow;
        mpWindow->osx.nsView = self;
        [mpWindow->osx.nsView setWantsLayer:YES];
        mpWindow->osx.nsView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawDuringViewResize;

        NSTrackingAreaOptions trackingOptions = NSTrackingMouseEnteredAndExited
                                              | NSTrackingMouseMoved
                                              | NSTrackingCursorUpdate
                                              | NSTrackingActiveInActiveApp //TODO maybe change that to allow multi-window mouse events...
                                              | NSTrackingEnabledDuringMouseDrag
                                              | NSTrackingInVisibleRect
                                              | NSTrackingAssumeInside;

        trackingArea = [[NSTrackingArea alloc] initWithRect:[self bounds] options:trackingOptions owner:self userInfo:nil];
        [self addTrackingArea:trackingArea];
        markedText = [[NSMutableAttributedString alloc] init];
    }
    return (self);
}

- (void)dealloc
{
    [trackingArea release];
    [markedText release];
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
    if(window->style & OC_WINDOW_STYLE_NO_TITLE)
    {
        [NSGraphicsContext saveGraphicsState];
        NSBezierPath* path = [NSBezierPath bezierPathWithRoundedRect:[self frame] xRadius:5 yRadius:5];
        [path addClip];
        [[NSColor whiteColor] set];
        NSRectFill([self frame]);
    }

    if(window->style & OC_WINDOW_STYLE_NO_TITLE)
    {
        [NSGraphicsContext restoreGraphicsState];
        [window->osx.nsWindow invalidateShadow];
    }
}

- (BOOL)acceptsFirstReponder
{
    return (YES);
}

- (void)cursorUpdate:(NSEvent*)event
{
    if(oc_appData.osx.cursor)
    {
        [oc_appData.osx.cursor set];
    }
    else
    {
        [[NSCursor arrowCursor] set];
    }
}

static void oc_process_mouse_button(NSEvent* nsEvent, oc_window_data* window, oc_mouse_button button, oc_key_action action)
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(window);
    event.type = OC_EVENT_MOUSE_BUTTON;
    event.key.action = action;
    event.key.code = button;
    event.key.mods = oc_convert_osx_mods([nsEvent modifierFlags]);
    event.key.clickCount = [nsEvent clickCount];

    oc_queue_event(&event);
}

- (void)mouseDown:(NSEvent*)nsEvent
{
    oc_process_mouse_button(nsEvent, window, OC_MOUSE_LEFT, OC_KEY_PRESS);
    [window->osx.nsWindow makeFirstResponder:self];
}

- (void)mouseUp:(NSEvent*)nsEvent
{
    oc_process_mouse_button(nsEvent, window, OC_MOUSE_LEFT, OC_KEY_RELEASE);
}

- (void)rightMouseDown:(NSEvent*)nsEvent
{
    oc_process_mouse_button(nsEvent, window, OC_MOUSE_RIGHT, OC_KEY_PRESS);
}

- (void)rightMouseUp:(NSEvent*)nsEvent
{
    oc_process_mouse_button(nsEvent, window, OC_MOUSE_RIGHT, OC_KEY_RELEASE);
}

- (void)otherMouseDown:(NSEvent*)nsEvent
{
    oc_process_mouse_button(nsEvent, window, [nsEvent buttonNumber], OC_KEY_PRESS);
}

- (void)otherMouseUp:(NSEvent*)nsEvent
{
    oc_process_mouse_button(nsEvent, window, [nsEvent buttonNumber], OC_KEY_RELEASE);
}

- (void)mouseDragged:(NSEvent*)nsEvent
{
    [self mouseMoved:nsEvent];
}

- (void)mouseMoved:(NSEvent*)nsEvent
{
    NSPoint p = [self convertPoint:[nsEvent locationInWindow] fromView:nil];

    NSRect frame = [[window->osx.nsWindow contentView] frame];
    oc_event event = {};
    event.type = OC_EVENT_MOUSE_MOVE;
    event.window = oc_window_handle_from_ptr(window);
    event.mouse.x = p.x;
    event.mouse.y = frame.size.height - p.y;
    event.mouse.deltaX = [nsEvent deltaX];
    event.mouse.deltaY = [nsEvent deltaY];
    event.mouse.mods = oc_convert_osx_mods([nsEvent modifierFlags]);

    oc_queue_event(&event);
}

- (void)scrollWheel:(NSEvent*)nsEvent
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(window);
    event.type = OC_EVENT_MOUSE_WHEEL;

    double factor = [nsEvent hasPreciseScrollingDeltas] ? 0.1 : 1.0;
    event.mouse.x = 0;
    event.mouse.y = 0;
    event.mouse.deltaX = -[nsEvent scrollingDeltaX] * factor;
    event.mouse.deltaY = -[nsEvent scrollingDeltaY] * factor;
    event.mouse.mods = oc_convert_osx_mods([nsEvent modifierFlags]);

    oc_queue_event(&event);
}

- (void)mouseExited:(NSEvent*)nsEvent
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(window);
    event.type = OC_EVENT_MOUSE_LEAVE;
    oc_queue_event(&event);
}

- (void)mouseEntered:(NSEvent*)nsEvent
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(window);
    event.type = OC_EVENT_MOUSE_ENTER;
    oc_queue_event(&event);
}

- (void)keyDown:(NSEvent*)nsEvent
{
    oc_key_action action = [nsEvent isARepeat] ? OC_KEY_REPEAT : OC_KEY_PRESS;

    oc_event event = {};
    event.window = oc_window_handle_from_ptr(window);
    event.type = OC_EVENT_KEYBOARD_KEY;
    event.key.action = action;
    event.key.code = oc_convert_osx_key([nsEvent keyCode]);
    event.key.mods = oc_convert_osx_mods([nsEvent modifierFlags]);

    oc_str8 label = oc_key_to_label(event.key.code);
    event.key.labelLen = label.len;
    memcpy(event.key.label, label.ptr, label.len);

    oc_queue_event(&event);

    [self interpretKeyEvents:@[ nsEvent ]];
}

- (void)keyUp:(NSEvent*)nsEvent
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(window);
    event.type = OC_EVENT_KEYBOARD_KEY;
    event.key.action = OC_KEY_RELEASE;
    event.key.code = oc_convert_osx_key([nsEvent keyCode]);
    event.key.mods = oc_convert_osx_mods([nsEvent modifierFlags]);

    oc_queue_event(&event);
}

- (void)flagsChanged:(NSEvent*)nsEvent
{
    oc_event event = {};
    event.window = oc_window_handle_from_ptr(window);
    event.type = OC_EVENT_KEYBOARD_MODS;
    event.key.mods = oc_convert_osx_mods([nsEvent modifierFlags]);

    oc_queue_event(&event);
}

- (BOOL)performKeyEquivalent:(NSEvent*)nsEvent
{
    if([nsEvent modifierFlags] & NSEventModifierFlagCommand)
    {
        if([nsEvent charactersIgnoringModifiers] == [NSString stringWithUTF8String:"w"])
        {
            [window->osx.nsWindow performClose:self];
            return (YES);
        }
        else if([nsEvent charactersIgnoringModifiers] == [NSString stringWithUTF8String:"q"])
        {
            oc_appData.shouldQuit = true;

            oc_event event = {};
            event.type = OC_EVENT_QUIT;

            oc_queue_event(&event);

            //[NSApp terminate:self];
            return (YES);
        }
    }

    return ([super performKeyEquivalent:nsEvent]);
}

- (BOOL)hasMarkedText
{
    return ([markedText length] > 0);
}

static const NSRange kEmptyRange = { NSNotFound, 0 };

- (NSRange)markedRange
{
    if([markedText length] > 0)
    {
        return (NSMakeRange(0, [markedText length] - 1));
    }
    else
    {
        return (kEmptyRange);
    }
}

- (NSRange)selectedRange
{
    return (kEmptyRange);
}

- (void)setMarkedText:(id)string
        selectedRange:(NSRange)selectedRange
     replacementRange:(NSRange)replacementRange
{
    [markedText release];

    if([string isKindOfClass:[NSAttributedString class]])
    {
        markedText = [[NSMutableAttributedString alloc] initWithAttributedString:string];
    }
    else
    {
        markedText = [[NSMutableAttributedString alloc] initWithString:string];
    }
}

- (void)unmarkText
{
    [[markedText mutableString] setString:@""];
}

- (NSArray*)validAttributesForMarkedText
{
    return ([NSArray array]);
}

- (NSAttributedString*)attributedSubstringForProposedRange:(NSRange)range
                                               actualRange:(NSRangePointer)actualRange
{
    return (nil);
}

- (NSUInteger)characterIndexForPoint:(NSPoint)point
{
    return (0);
}

- (NSRect)firstRectForCharacterRange:(NSRange)range
                         actualRange:(NSRangePointer)actualRange
{
    NSRect frame = [window->osx.nsView frame];
    return (NSMakeRect(frame.origin.x, frame.origin.y, 0.0, 0.0));
}

- (void)insertText:(id)string replacementRange:(NSRange)replacementRange
{
    NSString* characters;
    NSEvent* nsEvent = [NSApp currentEvent];
    oc_keymod_flags mods = oc_convert_osx_mods([nsEvent modifierFlags]);

    if([string isKindOfClass:[NSAttributedString class]])
    {
        characters = [string string];
    }
    else
    {
        characters = (NSString*)string;
    }

    NSRange range = NSMakeRange(0, [characters length]);
    while(range.length)
    {
        oc_utf32 codepoint = 0;

        if([characters getBytes:&codepoint
                      maxLength:sizeof(codepoint)
                     usedLength:NULL
                       encoding:NSUTF32StringEncoding
                        options:0
                          range:range
                 remainingRange:&range])
        {
            if(codepoint >= 0xf700 && codepoint <= 0xf7ff)
            {
                continue;
            }

            oc_event event = {};
            event.window = oc_window_handle_from_ptr(window);
            event.type = OC_EVENT_KEYBOARD_CHAR;
            event.character.codepoint = codepoint;

            oc_str8 seq = oc_utf8_encode(event.character.sequence, event.character.codepoint);
            event.character.seqLen = seq.len;

            oc_queue_event(&event);
        }
    }
    [self unmarkText];
}

- (void)doCommandBySelector:(SEL)selector
{
}

@end //@implementation OCView

//***************************************************************
//			public API
//***************************************************************

//---------------------------------------------------------------
// App public API
//---------------------------------------------------------------

void oc_init()
{
    @autoreleasepool
    {
        if(!oc_appData.init)
        {
            memset(&oc_appData, 0, sizeof(oc_appData));

            oc_arena_init(&oc_appData.eventArena);

            oc_clock_init();

            oc_init_osx_keys();
            oc_update_keyboard_layout();
            oc_install_keyboard_layout_listener();

            oc_init_window_handles();

            oc_ringbuffer_init(&oc_appData.eventQueue, 16);

            [OCApplication sharedApplication];
            OCAppDelegate* delegate = [[OCAppDelegate alloc] init];
            [NSApp setDelegate:delegate];

            [NSThread detachNewThreadSelector:@selector(noOpThread:)
                                     toTarget:NSApp
                                   withObject:nil];

            oc_appData.init = true;

            [NSApp run];
            [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
            [NSApp activateIgnoringOtherApps:YES];
        }
    }
}

void oc_terminate()
{
    //TODO: proper app data cleanup (eg delegate, etc)
    if(oc_appData.init)
    {
        oc_arena_cleanup(&oc_appData.eventArena);
        oc_appData = (oc_app){ 0 };
    }
}

bool oc_should_quit()
{
    return (oc_appData.shouldQuit);
}

void oc_do_quit()
{
    oc_appData.shouldQuit = true;
}

void oc_cancel_quit()
{
    oc_appData.shouldQuit = false;
}

void oc_request_quit()
{
    oc_appData.shouldQuit = true;
    oc_event event = {};
    event.type = OC_EVENT_QUIT;
    oc_queue_event(&event);
}

void oc_set_cursor(oc_mouse_cursor cursor)
{
    switch(cursor)
    {
        case OC_MOUSE_CURSOR_ARROW:
        {
            oc_appData.osx.cursor = [NSCursor arrowCursor];
        }
        break;
        case OC_MOUSE_CURSOR_RESIZE_0:
        {
            oc_appData.osx.cursor = [[NSCursor class] performSelector:@selector(_windowResizeEastWestCursor)];
        }
        break;
        case OC_MOUSE_CURSOR_RESIZE_90:
        {
            oc_appData.osx.cursor = [[NSCursor class] performSelector:@selector(_windowResizeNorthSouthCursor)];
        }
        break;
        case OC_MOUSE_CURSOR_RESIZE_45:
        {
            oc_appData.osx.cursor = [[NSCursor class] performSelector:@selector(_windowResizeNorthEastSouthWestCursor)];
        }
        break;
        case OC_MOUSE_CURSOR_RESIZE_135:
        {
            oc_appData.osx.cursor = [[NSCursor class] performSelector:@selector(_windowResizeNorthWestSouthEastCursor)];
        }
        break;
        case OC_MOUSE_CURSOR_TEXT:
        {
            oc_appData.osx.cursor = [NSCursor IBeamCursor];
        }
        break;
    }
    [oc_appData.osx.cursor set];
}

void oc_clipboard_clear()
{
    @autoreleasepool
    {
        NSPasteboard* pb = [NSPasteboard generalPasteboard];
        [pb clearContents];
    }
}

void oc_clipboard_set_string(oc_str8 string)
{
    @autoreleasepool
    {

        NSString* nsString = [[NSString alloc] initWithBytes:string.ptr length:string.len encoding:NSUTF8StringEncoding];
        NSPasteboard* pb = [NSPasteboard generalPasteboard];
        [pb writeObjects:[[NSArray alloc] initWithObjects:nsString, nil]];
    }
}

oc_str8 oc_clipboard_copy_string(oc_str8 backing)
{
    @autoreleasepool
    {
        //WARN(martin): maxSize includes space for a null terminator

        NSPasteboard* pb = [NSPasteboard generalPasteboard];
        NSString* nsString = [pb stringForType:NSPasteboardTypeString];
        const char* cString = [nsString UTF8String];
        u32 len = oc_min(backing.len - 1, strlen(cString)); //length without null terminator
        strncpy(backing.ptr, cString, backing.len - 1);
        backing.ptr[len] = '\0';

        oc_str8 result = oc_str8_slice(backing, 0, len);
        return (result);
    }
}

oc_str8 oc_clipboard_get_string(oc_arena* arena)
{
    @autoreleasepool
    {
        //WARN(martin): maxSize includes space for a null terminator

        NSPasteboard* pb = [NSPasteboard generalPasteboard];
        NSString* nsString = [pb stringForType:NSPasteboardTypeString];
        const char* cString = [nsString UTF8String];
        oc_str8 result = oc_str8_push_cstring(arena, cString);
        return (result);
    }
}

bool oc_clipboard_has_tag(const char* tag)
{
    @autoreleasepool
    {

        NSString* tagString = [[NSString alloc] initWithUTF8String:tag];
        NSArray* tagArray = [NSArray arrayWithObjects:tagString, nil];

        NSPasteboard* pb = [NSPasteboard generalPasteboard];
        NSString* available = [pb availableTypeFromArray:tagArray];

        return (available != nil);
    }
}

void oc_clipboard_set_data_for_tag(const char* tag, oc_str8 string)
{
    @autoreleasepool
    {

        NSString* tagString = [[NSString alloc] initWithUTF8String:tag];
        NSArray* tagArray = [NSArray arrayWithObjects:tagString, nil];
        NSData* nsData = [NSData dataWithBytes:string.ptr length:string.len];

        NSPasteboard* pb = [NSPasteboard generalPasteboard];
        [pb addTypes:tagArray owner:nil];
        [pb setData:nsData forType:tagString];
    }
}

oc_str8 oc_clipboard_get_data_for_tag(oc_arena* arena, const char* tag)
{
    @autoreleasepool
    {

        NSString* tagString = [[NSString alloc] initWithUTF8String:tag];

        NSPasteboard* pb = [NSPasteboard generalPasteboard];
        NSData* nsData = [pb dataForType:tagString];
        oc_str8 result = oc_str8_push_buffer(arena, [nsData length], (char*)[nsData bytes]);
        return (result);
    }
}

//---------------------------------------------------------------
// Window public API
//---------------------------------------------------------------

oc_window oc_window_create(oc_rect contentRect, oc_str8 title, oc_window_style style)
{
    @autoreleasepool
    {
        oc_window_data* window = oc_window_alloc();
        if(!window)
        {
            oc_log_error("Could not allocate window data\n");
            return ((oc_window){ 0 });
        }

        window->style = style;
        window->shouldClose = false;
        window->hidden = true;

        u32 styleMask = oc_osx_get_window_style_mask(style);

        NSRect screenRect = [[NSScreen mainScreen] frame];
        NSRect rect = NSMakeRect(contentRect.x,
                                 screenRect.size.height - contentRect.y - contentRect.h,
                                 contentRect.w,
                                 contentRect.h);

        window->osx.nsWindow = [[OCWindow alloc] initWithWindowData:window contentRect:rect styleMask:styleMask];
        window->osx.nsWindowDelegate = [[OCWindowDelegate alloc] initWithWindowData:window];

        [window->osx.nsWindow setDelegate:(id)window->osx.nsWindowDelegate];

        [window->osx.nsWindow setTitle:[[NSString alloc] initWithBytes:(void*)title.ptr length:title.len encoding:NSUTF8StringEncoding]];

        if(style & OC_WINDOW_STYLE_NO_TITLE)
        {
            [window->osx.nsWindow setOpaque:NO];
            [window->osx.nsWindow setBackgroundColor:[NSColor clearColor]];
            [window->osx.nsWindow setHasShadow:YES];
        }
        if(style & OC_WINDOW_STYLE_FLOAT)
        {
            [window->osx.nsWindow setLevel:NSFloatingWindowLevel];
            [window->osx.nsWindow setHidesOnDeactivate:YES];
        }
        if(style & OC_WINDOW_STYLE_NO_BUTTONS)
        {
            [[window->osx.nsWindow standardWindowButton:NSWindowCloseButton] setHidden:YES];
            [[window->osx.nsWindow standardWindowButton:NSWindowMiniaturizeButton] setHidden:YES];
            [[window->osx.nsWindow standardWindowButton:NSWindowZoomButton] setHidden:YES];
        }

        OCView* view = [[OCView alloc] initWithWindowData:window];
        [view setCanDrawConcurrently:YES];

        [window->osx.nsWindow setContentView:view];
        [window->osx.nsWindow makeFirstResponder:view];
        [window->osx.nsWindow setAcceptsMouseMovedEvents:YES];

        oc_window windowHandle = oc_window_handle_from_ptr(window);

        return (windowHandle);
    } //autoreleasepool
}

void oc_window_destroy(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            [windowData->osx.nsWindow orderOut:nil];

            [windowData->osx.nsWindow setDelegate:nil];
            [windowData->osx.nsWindowDelegate release];
            windowData->osx.nsWindowDelegate = nil;

            [windowData->osx.nsView release];
            windowData->osx.nsView = nil;

            [windowData->osx.nsWindow close]; //also release the window

            oc_window_recycle_ptr(windowData);
        }
    } // autoreleasepool
}

bool oc_window_should_close(oc_window window)
{
    oc_window_data* windowData = oc_window_ptr_from_handle(window);
    if(windowData)
    {
        return (windowData->shouldClose);
    }
    else
    {
        return (false);
    }
}

void oc_window_cancel_close(oc_window window)
{
    oc_window_data* windowData = oc_window_ptr_from_handle(window);
    if(windowData)
    {
        windowData->shouldClose = false;
    }
}

void oc_window_request_close(oc_window window)
{
    oc_window_data* windowData = oc_window_ptr_from_handle(window);
    if(windowData)
    {
        [windowData->osx.nsWindow close];
        //NOTE(martin): this will call our window delegate willClose method
    }
}

void* oc_window_native_pointer(oc_window window)
{
    oc_window_data* windowData = oc_window_ptr_from_handle(window);
    if(windowData)
    {
        return ((__bridge void*)windowData->osx.nsWindow);
    }
    else
    {
        return (0);
    }
}

void oc_window_center(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            [windowData->osx.nsWindow center];
        }
    }
}

bool oc_window_is_hidden(oc_window window)
{
    oc_window_data* windowData = oc_window_ptr_from_handle(window);
    if(windowData)
    {
        return (windowData->hidden);
    }
    else
    {
        return (false);
    }
}

bool oc_window_is_focused(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            return ([windowData->osx.nsWindow isKeyWindow]);
        }
        else
        {
            return (false);
        }
    }
}

void oc_window_hide(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            windowData->hidden = true;
            [windowData->osx.nsWindow orderOut:nil];
        }
    }
}

void oc_window_focus(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            [windowData->osx.nsWindow makeKeyWindow];
        }
    }
}

void oc_window_send_to_back(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            [windowData->osx.nsWindow orderBack:nil];
        }
    }
}

void oc_window_bring_to_front(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            windowData->hidden = false;
            [windowData->osx.nsWindow orderFront:nil];
        }
    }
}

void oc_window_bring_to_front_and_focus(oc_window window)
{
    oc_window_bring_to_front(window);
    oc_window_focus(window);
}

oc_rect oc_window_get_frame_rect(oc_window window)
{
    oc_rect rect = { 0 };
    oc_window_data* windowData = oc_window_ptr_from_handle(window);
    if(windowData)
    {
        NSRect frameRect = windowData->osx.nsWindow.frame;
        NSScreen* screen = windowData->osx.nsWindow.screen;

        rect = (oc_rect){
            frameRect.origin.x,
            screen.frame.size.height - frameRect.origin.y - frameRect.size.height,
            frameRect.size.width,
            frameRect.size.height
        };
    }
    return (rect);
}

void oc_window_set_frame_rect(oc_window window, oc_rect rect)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            NSScreen* screen = windowData->osx.nsWindow.screen;
            NSRect frameRect = {
                rect.x,
                screen.frame.size.height - rect.y - rect.h,
                rect.w,
                rect.h
            };
            [windowData->osx.nsWindow setFrame:frameRect display:YES];
        }
    }
}

oc_rect oc_window_get_content_rect(oc_window window)
{
    @autoreleasepool
    {
        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            NSScreen* screen = [windowData->osx.nsWindow screen];
            NSView* view = [windowData->osx.nsWindow contentView];
            NSRect contentRect = [windowData->osx.nsWindow convertRectToScreen:view.frame];

            oc_rect rect = {
                contentRect.origin.x,
                screen.frame.size.height - contentRect.origin.y - contentRect.size.height,
                contentRect.size.width,
                contentRect.size.height
            };

            return (rect);
        }
        else
        {
            return ((oc_rect){});
        }
    }
}

void oc_window_set_content_rect(oc_window window, oc_rect rect)
{
    @autoreleasepool
    {

        oc_window_data* windowData = oc_window_ptr_from_handle(window);
        if(windowData)
        {
            NSScreen* screen = [windowData->osx.nsWindow screen];
            NSRect contentRect = {
                rect.x,
                screen.frame.size.height - rect.y - rect.h,
                rect.w,
                rect.h
            };

            NSRect frameRect = [windowData->osx.nsWindow frameRectForContentRect:contentRect];
            [windowData->osx.nsWindow setFrame:frameRect display:YES];
        }
    }
}

//--------------------------------------------------------------------
// platform surface
//--------------------------------------------------------------------

void* oc_osx_surface_native_layer(oc_surface_data* surface)
{
    return ((void*)surface->layer.caLayer);
}

oc_vec2 oc_osx_surface_contents_scaling(oc_surface_data* surface)
{
    @autoreleasepool
    {
        f32 contentsScale = [surface->layer.caLayer contentsScale];
        oc_vec2 res = { contentsScale, contentsScale };
        return (res);
    }
}

oc_vec2 oc_osx_surface_get_size(oc_surface_data* surface)
{
    @autoreleasepool
    {
        CGRect bounds = surface->layer.caLayer.bounds;
        oc_vec2 res = { bounds.size.width, bounds.size.height };
        return (res);
    }
}

bool oc_osx_surface_get_hidden(oc_surface_data* surface)
{
    @autoreleasepool
    {
        return ([surface->layer.caLayer isHidden]);
    }
}

void oc_osx_surface_set_hidden(oc_surface_data* surface, bool hidden)
{
    @autoreleasepool
    {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        [surface->layer.caLayer setHidden:hidden];
        [CATransaction commit];
    }
}

void oc_surface_cleanup(oc_surface_data* surface)
{
    @autoreleasepool
    {
        [surface->layer.caLayer release];
    }
}

void oc_surface_init_for_window(oc_surface_data* surface, oc_window_data* window)
{
    @autoreleasepool
    {
        surface->nativeLayer = oc_osx_surface_native_layer;
        surface->contentsScaling = oc_osx_surface_contents_scaling;
        surface->getSize = oc_osx_surface_get_size;
        surface->getHidden = oc_osx_surface_get_hidden;
        surface->setHidden = oc_osx_surface_set_hidden;

        surface->layer.caLayer = [[CALayer alloc] init];
        [surface->layer.caLayer retain];

        NSRect frame = [[window->osx.nsWindow contentView] frame];
        CGSize size = frame.size;
        surface->layer.caLayer.frame = (CGRect){ { 0, 0 }, size };
        surface->layer.caLayer.contentsScale = window->osx.nsView.layer.contentsScale;

        surface->layer.caLayer.autoresizingMask = kCALayerWidthSizable | kCALayerHeightSizable;

        [window->osx.nsView.layer addSublayer:surface->layer.caLayer];
    }
}

//------------------------------------------------------------------------------------------------
// Remote surfaces
//------------------------------------------------------------------------------------------------
oc_surface_id oc_osx_surface_remote_id(oc_surface_data* surface)
{
    oc_surface_id remoteID = 0;
    if(surface->layer.caContext)
    {
        @autoreleasepool
        {
            remoteID = (oc_surface_id)[surface->layer.caContext contextId];
        }
    }
    return (remoteID);
}

void oc_surface_init_remote(oc_surface_data* surface, u32 width, u32 height)
{
    @autoreleasepool
    {

        surface->nativeLayer = oc_osx_surface_native_layer;
        surface->contentsScaling = oc_osx_surface_contents_scaling;
        surface->getSize = oc_osx_surface_get_size;
        surface->getHidden = oc_osx_surface_get_hidden;
        surface->setHidden = oc_osx_surface_set_hidden;
        surface->remoteID = oc_osx_surface_remote_id;

        surface->layer.caLayer = [[CALayer alloc] init];
        [surface->layer.caLayer retain];
        [surface->layer.caLayer setFrame:(CGRect){ { 0, 0 }, { width, height } }];

        NSDictionary* dict = [[NSDictionary alloc] init];
        CGSConnectionID connectionID = CGSMainConnectionID();
        surface->layer.caContext = [CAContext contextWithCGSConnection:connectionID options:dict];
        [surface->layer.caContext retain];
        [surface->layer.caContext setLayer:surface->layer.caLayer];
    }
}

void oc_osx_surface_host_connect(oc_surface_data* surface, oc_surface_id remoteID)
{
    @autoreleasepool
    {
        [(CALayerHost*)surface->layer.caLayer setContextId:(CAContextID)remoteID];
    }
}

void oc_surface_init_host(oc_surface_data* surface, oc_window_data* window)
{
    @autoreleasepool
    {

        surface->api = OC_HOST;
        surface->nativeLayer = oc_osx_surface_native_layer;
        surface->contentsScaling = oc_osx_surface_contents_scaling;
        surface->getSize = oc_osx_surface_get_size;
        surface->getHidden = oc_osx_surface_get_hidden;
        surface->setHidden = oc_osx_surface_set_hidden;
        surface->hostConnect = oc_osx_surface_host_connect;

        surface->layer.caLayer = [[CALayerHost alloc] init];
        [surface->layer.caLayer retain];

        NSRect frame = [[window->osx.nsWindow contentView] frame];
        CGSize size = frame.size;
        [surface->layer.caLayer setFrame:(CGRect){ { 0, 0 }, size }];

        [window->osx.nsView.layer addSublayer:surface->layer.caLayer];
    }
}

oc_surface_data* oc_osx_surface_create_host(oc_window windowHandle)
{
    oc_surface_data* surface = 0;
    oc_window_data* window = oc_window_ptr_from_handle(windowHandle);
    if(window)
    {
        surface = oc_malloc_type(oc_surface_data);
        if(surface)
        {
            oc_surface_init_host(surface, window);
        }
    }
    return (surface);
}

//--------------------------------------------------------------------
// view management
//--------------------------------------------------------------------
/*
oc_view oc_view_create(oc_window windowHandle, oc_rect frame)
{@autoreleasepool{
	oc_window_data* window = oc_window_ptr_from_handle(windowHandle);
	if(!window)
	{
		oc_log_error("Can't create view for nil window\n");
		return(oc_view_nil());
	}

	oc_view_data* view = oc_view_alloc();
	if(!view)
	{
		oc_log_error("Could not allocate view data\n");
		return(oc_view_nil());
	}

	view->window = windowHandle;

	NSRect nsFrame = {{frame.x, frame.y}, {frame.w, frame.h}};
	view->nsView = [[NSView alloc] initWithFrame: nsFrame];
	[view->nsView setWantsLayer:YES];

	[[window->osx.nsWindow contentView] addSubview: view->nsView];

	return(oc_view_handle_from_ptr(view));
}}

void oc_view_destroy(oc_view viewHandle)
{@autoreleasepool{
	oc_view_data* view = oc_view_ptr_from_handle(viewHandle);
	if(!view)
	{
		return;
	}

	oc_window_data* window = oc_window_ptr_from_handle(view->window);
	if(!window)
	{
		return;
	}

	[view->nsView removeFromSuperview];

	oc_view_recycle_ptr(view);
}}

void oc_view_set_frame(oc_view viewHandle, oc_rect frame)
{
	oc_view_data* view = oc_view_ptr_from_handle(viewHandle);
	if(!view)
	{
		return;
	}

	NSRect nsFrame = {{frame.x, frame.y}, {frame.w, frame.h}};
	[view->nsView setFrame: nsFrame];

	if(!oc_surface_is_nil(view->surface))
	{
		oc_surface_resize(view->surface, frame.w, frame.h);
	}
}
*/
//--------------------------------------------------------------------
// Main loop throttle
//--------------------------------------------------------------------

void oc_set_target_fps(u32 fps)
{
    oc_appData.frameStats.targetFramePeriod = 1. / (f64)fps;
    oc_appData.frameStats.workTime = 0;
    oc_appData.frameStats.remainingTime = 0;

    if(oc_appData.osx.frameTimer)
    {
        [oc_appData.osx.frameTimer invalidate];
    }

    oc_appData.osx.frameTimer = [NSTimer timerWithTimeInterval:oc_appData.frameStats.targetFramePeriod
                                                        target:[NSApp delegate]
                                                      selector:@selector(timerElapsed:)
                                                      userInfo:nil
                                                       repeats:YES];

    [[NSRunLoop currentRunLoop] addTimer:oc_appData.osx.frameTimer forMode:NSRunLoopCommonModes];
}

/*
void oc_begin_frame()
{
	oc_appData.frameStats.start = oc_get_elapsed_seconds();

	LOG_DEBUG("workTime = %.6f (%.6f fps), remaining = %.6f\n",
	             oc_appData.frameStats.workTime,
	             1/oc_appData.frameStats.workTime,
	             oc_appData.frameStats.remainingTime);

}

void oc_end_frame()
{
	oc_appData.frameStats.workTime = oc_get_elapsed_seconds() - oc_appData.frameStats.start;
	oc_appData.frameStats.remainingTime = oc_appData.frameStats.targetFramePeriod - oc_appData.frameStats.workTime;

	while(oc_appData.frameStats.remainingTime > 100e-9)
	{
		if(oc_appData.frameStats.remainingTime > 10e-6)
		{
			oc_sleep_nano(oc_appData.frameStats.remainingTime*0.8*1e9);
		}
		oc_appData.frameStats.workTime = oc_get_elapsed_seconds() - oc_appData.frameStats.start;
		oc_appData.frameStats.remainingTime = oc_appData.frameStats.targetFramePeriod - oc_appData.frameStats.workTime;
	}
}
*/

//--------------------------------------------------------------------
// Events handling
//--------------------------------------------------------------------

void oc_set_live_resize_callback(oc_live_resize_callback callback, void* data)
{
    oc_appData.liveResizeCallback = callback;
    oc_appData.liveResizeData = data;
}

void oc_pump_events(f64 timeout)
{
    @autoreleasepool
    {
        bool accumulate = false;
        NSDate* date = 0;
        if(timeout > 0)
        {
            date = [NSDate dateWithTimeIntervalSinceNow:(double)timeout];
        }
        else if(timeout == 0)
        {
            date = [NSDate distantPast];
            accumulate = true;
        }
        else
        {
            date = [NSDate distantFuture];
        }

        for(;;)
        {
            NSEvent* event = [NSApp nextEventMatchingMask:NSEventMaskAny
                                                untilDate:date
                                                   inMode:NSDefaultRunLoopMode
                                                  dequeue:YES];

            if(event != nil)
            {
                [NSApp sendEvent:event];

                if(!accumulate)
                {
                    break;
                }
            }
            else
            {
                break;
            }
        }
    }
}

i32 oc_dispatch_on_main_thread_sync(oc_window main_window, oc_dispatch_proc proc, void* user)
{
    __block i32 result = 0;
    dispatch_block_t block = ^{
      result = proc(user);
    };

    if([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }

    return (result);
}

//--------------------------------------------------------------------
// system dialogs windows
//--------------------------------------------------------------------

oc_str8 oc_open_dialog(oc_arena* arena,
                       oc_str8 title,
                       oc_str8 defaultPath,
                       oc_str8_list filters,
                       bool directory)
{
    @autoreleasepool
    {
        NSWindow* keyWindow = [NSApp keyWindow];

        NSOpenPanel* dialog = [NSOpenPanel openPanel];
        [dialog setLevel:CGShieldingWindowLevel()];

        if(filters.eltCount)
        {
            NSMutableArray* fileTypesArray = [NSMutableArray array];

            oc_list_for(&filters.list, elt, oc_str8_elt, listElt)
            {
                oc_str8 string = elt->string;
                NSString* filter = [[NSString alloc] initWithBytes:string.ptr length:string.len encoding:NSUTF8StringEncoding];
                [fileTypesArray addObject:filter];
            }
            [dialog setAllowedFileTypes:fileTypesArray];
        }
        // Enable options in the dialog.
        if(directory)
        {
            [dialog setCanChooseDirectories:YES];
        }
        else
        {
            [dialog setCanChooseFiles:YES];
        }

        [dialog setAllowsMultipleSelection:FALSE];

        NSString* nsPath = 0;
        ;
        if(defaultPath.len)
        {
            nsPath = [[NSString alloc] initWithBytes:defaultPath.ptr length:defaultPath.len encoding:NSUTF8StringEncoding];
        }
        else
        {
            nsPath = [NSString stringWithUTF8String:"~"];
        }
        nsPath = [nsPath stringByExpandingTildeInPath];

        [dialog setDirectoryURL:[NSURL fileURLWithPath:nsPath]];

        // Display the dialog box. If the OK pressed,
        // process the files.

        if([dialog runModal] == NSModalResponseOK)
        {
            // Gets list of all files selected
            NSArray* files = [dialog URLs];
            //TODO: Loop through the files and process them.

            const char* result = [[[files objectAtIndex:0] path] UTF8String];

            oc_str8 path = oc_str8_push_cstring(arena, result);
            [keyWindow makeKeyWindow];

            return (path);
        }
        else
        {
            [keyWindow makeKeyWindow];
            return ((oc_str8){ 0, 0 });
        }
    }
}

oc_str8 oc_save_dialog(oc_arena* arena,
                       oc_str8 title,
                       oc_str8 defaultPath,
                       oc_str8_list filters)
{
    @autoreleasepool
    {
        NSWindow* keyWindow = [NSApp keyWindow];

        NSSavePanel* dialog = [NSSavePanel savePanel];
        [dialog setLevel:CGShieldingWindowLevel()];

        if(filters.eltCount)
        {
            NSMutableArray* fileTypesArray = [NSMutableArray array];

            oc_list_for(&filters.list, elt, oc_str8_elt, listElt)
            {
                oc_str8 string = elt->string;
                NSString* filter = [[NSString alloc] initWithBytes:string.ptr length:string.len encoding:NSUTF8StringEncoding];
                [fileTypesArray addObject:filter];
            }
            [dialog setAllowedFileTypes:fileTypesArray];
        }

        NSString* nsPath = 0;
        ;
        if(defaultPath.len)
        {
            nsPath = [[NSString alloc] initWithBytes:defaultPath.ptr length:defaultPath.len encoding:NSUTF8StringEncoding];
        }
        else
        {
            nsPath = [NSString stringWithUTF8String:"~"];
        }
        nsPath = [nsPath stringByExpandingTildeInPath];

        [dialog setDirectoryURL:[NSURL fileURLWithPath:nsPath]];

        // Display the dialog box. If the OK pressed,
        // process the files.

        if([dialog runModal] == NSModalResponseOK)
        {
            // Gets list of all files selected
            NSURL* files = [dialog URL];
            // Loop through the files and process them.

            const char* result = [[files path] UTF8String];

            oc_str8 path = oc_str8_push_cstring(arena, result);
            [keyWindow makeKeyWindow];
            return (path);
        }
        else
        {
            [keyWindow makeKeyWindow];
            return ((oc_str8){ 0, 0 });
        }
    }
}

int oc_alert_popup(oc_str8 title,
                   oc_str8 message,
                   oc_str8_list options)
{
    __block int result = 0;

    dispatch_block_t block = ^{
      @autoreleasepool
      {
          NSWindow* keyWindow = [NSApp keyWindow];

          NSAlert* alert = [[NSAlert alloc] init];
          NSString* string;

          oc_list_for_reverse((oc_list*)&options.list, elt, oc_str8_elt, listElt)
          {
              string = [[NSString alloc] initWithBytes:elt->string.ptr length:elt->string.len encoding:NSUTF8StringEncoding];
              [alert addButtonWithTitle:string];
              [string release];
          }
          string = [[NSString alloc] initWithBytes:title.ptr length:title.len encoding:NSUTF8StringEncoding];
          [alert setMessageText:string];
          [string release];

          string = [[NSString alloc] initWithBytes:message.ptr length:message.len encoding:NSUTF8StringEncoding];
          [alert setInformativeText:string];
          [string release];

          [alert setAlertStyle:NSAlertStyleWarning];
          result = options.eltCount - ([alert runModal] - NSAlertFirstButtonReturn) - 1;
          [keyWindow makeKeyWindow];
      }
    };

    if([NSThread isMainThread])
    {
        block();
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), block);
    }
    return (result);
}

//--------------------------------------------------------------------
// file system stuff... //TODO: move elsewhere
//--------------------------------------------------------------------

int oc_file_move(oc_str8 from, oc_str8 to)
{
    @autoreleasepool
    {
        NSString* nsFrom = [[NSString alloc] initWithBytes:from.ptr length:from.len encoding:NSUTF8StringEncoding];
        NSString* nsTo = [[NSString alloc] initWithBytes:to.ptr length:to.len encoding:NSUTF8StringEncoding];
        NSError* err;
        if([[NSFileManager defaultManager] moveItemAtPath:nsFrom toPath:nsTo error:&err] == YES)
        {
            return (0);
        }
        else
        {
            return (-1);
        }
    }
}

int oc_file_remove(oc_str8 path)
{
    @autoreleasepool
    {
        NSString* nsPath = [[NSString alloc] initWithBytes:path.ptr length:path.len encoding:NSUTF8StringEncoding];
        NSError* err;
        if([[NSFileManager defaultManager] removeItemAtPath:nsPath error:&err] == YES)
        {
            return (0);
        }
        else
        {
            return (-1);
        }
    }
}

int oc_directory_create(oc_str8 path)
{
    @autoreleasepool
    {

        NSString* nsPath = [[NSString alloc] initWithBytes:path.ptr length:path.len encoding:NSUTF8StringEncoding];
        NSError* err;
        if([[NSFileManager defaultManager] createDirectoryAtPath:nsPath
                                     withIntermediateDirectories:YES
                                                      attributes:nil
                                                           error:&err]
           == YES)
        {
            return (0);
        }
        else
        {
            return (-1);
        }
    }
}