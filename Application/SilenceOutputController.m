/*
 SilenceOutputController.m

 This file is part of Audirvana.

 Audirvana is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 */

#import "SilenceOutputController.h"
#import "AppController.h"

/* PCM sample rates (Hz) */
static const Float64 kSilenceSampleRates[] = {
    44100.0, 48000.0, 88200.0, 96000.0,
    176400.0, 192000.0, 352800.0, 384000.0, 705600.0, 768000.0,
    /* DSD DoP equivalent PCM rates */
    176400.0,   /* DSD64  → DoP 176.4 kHz */
    352800.0,   /* DSD128 → DoP 352.8 kHz */
    705600.0,   /* DSD256 → DoP 705.6 kHz */
    1411200.0   /* DSD512 → DoP 1411.2 kHz */
};

static const BOOL kSilenceIsDSD[] = {
    NO, NO, NO, NO,
    NO, NO, NO, NO, NO, NO,
    YES, YES, YES, YES
};

static NSString * const kSilenceRateLabels[] = {
    @"PCM 44.1 kHz",
    @"PCM 48 kHz",
    @"PCM 88.2 kHz",
    @"PCM 96 kHz",
    @"PCM 176.4 kHz",
    @"PCM 192 kHz",
    @"PCM 352.8 kHz",
    @"PCM 384 kHz",
    @"PCM 705.6 kHz",
    @"PCM 768 kHz",
    @"DSD64  (DoP 176.4 kHz)",
    @"DSD128 (DoP 352.8 kHz)",
    @"DSD256 (DoP 705.6 kHz)",
    @"DSD512 (DoP 1411.2 kHz)"
};

#define kNumPCMRates  10
#define kNumDSDRates   4
#define kNumAllRates  (kNumPCMRates + kNumDSDRates)

@implementation SilenceOutputController

- (id)initWithAppController:(AppController*)controller
{
    self = [super init];
    if (self) {
        appController = controller;
        isActive = NO;
        [self buildPanel];
    }
    return self;
}

- (void)dealloc
{
    [panel release];
    [super dealloc];
}

- (void)buildPanel
{
    panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 340, 150)
                                       styleMask:(NSTitledWindowMask | NSClosableWindowMask)
                                         backing:NSBackingStoreBuffered
                                           defer:NO];
    [panel setTitle:@"Silence Output"];
    [panel setFloatingPanel:YES];
    [panel setHidesOnDeactivate:NO];

    NSView *cv = [panel contentView];

    /* ── Sample rate label ── */
    NSTextField *rateLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(12, 110, 96, 20)] autorelease];
    [rateLabel setStringValue:@"Sample Rate:"];
    [rateLabel setBezeled:NO];
    [rateLabel setDrawsBackground:NO];
    [rateLabel setEditable:NO];
    [rateLabel setAlignment:NSRightTextAlignment];
    [cv addSubview:rateLabel];

    /* ── Sample rate popup ── */
    sampleRatePopup = [[NSPopUpButton alloc] initWithFrame:NSMakeRect(114, 106, 214, 26) pullsDown:NO];
    for (int i = 0; i < kNumPCMRates; i++)
        [sampleRatePopup addItemWithTitle:kSilenceRateLabels[i]];
    [[sampleRatePopup menu] addItem:[NSMenuItem separatorItem]];
    for (int i = kNumPCMRates; i < kNumAllRates; i++)
        [sampleRatePopup addItemWithTitle:kSilenceRateLabels[i]];
    [cv addSubview:sampleRatePopup];

    /* ── Status label ── */
    statusLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(12, 72, 316, 18)];
    [statusLabel setStringValue:@"Ready"];
    [statusLabel setBezeled:NO];
    [statusLabel setDrawsBackground:NO];
    [statusLabel setEditable:NO];
    [statusLabel setAlignment:NSCenterTextAlignment];
    [statusLabel setFont:[NSFont systemFontOfSize:11.0f]];
    [statusLabel setTextColor:[NSColor darkGrayColor]];
    [cv addSubview:statusLabel];

    /* ── Start button ── */
    startButton = [[NSButton alloc] initWithFrame:NSMakeRect(60, 16, 90, 32)];
    [startButton setTitle:@"Start"];
    [startButton setBezelStyle:NSRoundedBezelStyle];
    [startButton setTarget:self];
    [startButton setAction:@selector(startSilence:)];
    [cv addSubview:startButton];

    /* ── Stop button ── */
    stopButton = [[NSButton alloc] initWithFrame:NSMakeRect(190, 16, 90, 32)];
    [stopButton setTitle:@"Stop"];
    [stopButton setBezelStyle:NSRoundedBezelStyle];
    [stopButton setTarget:self];
    [stopButton setAction:@selector(stopSilence:)];
    [stopButton setEnabled:NO];
    [cv addSubview:stopButton];

    [sampleRatePopup release];
    [statusLabel release];
    [startButton release];
    [stopButton release];
}

- (void)showPanel
{
    [panel center];
    [panel makeKeyAndOrderFront:nil];
}

- (void)setIsActive:(BOOL)active
{
    isActive = active;
    [startButton setEnabled:!active];
    [stopButton setEnabled:active];
    if (!active && [[statusLabel stringValue] isEqualToString:@"Silence output active"])
        [statusLabel setStringValue:@"Stopped"];
}

- (void)updateStatus:(NSString*)status
{
    [statusLabel setStringValue:status];
}

- (IBAction)startSilence:(id)sender
{
    /* Resolve selected popup index to sample rate / isDSD flag.
       The popup has a separator between PCM and DSD items, so the
       raw selectedItem tag approach won't work; use the title instead. */
    NSString *selectedTitle = [[sampleRatePopup selectedItem] title];

    int selectedIndex = -1;
    for (int i = 0; i < kNumAllRates; i++) {
        if ([selectedTitle isEqualToString:kSilenceRateLabels[i]]) {
            selectedIndex = i;
            break;
        }
    }
    if (selectedIndex < 0) return;

    Float64 rate  = kSilenceSampleRates[selectedIndex];
    BOOL    isDSD = kSilenceIsDSD[selectedIndex];

    [statusLabel setStringValue:@"Initializing..."];
    [startButton setEnabled:NO];

    [appController startSilenceOutput:rate isDSDMode:isDSD];
}

- (IBAction)stopSilence:(id)sender
{
    [appController stopSilenceOutput];
}

@end
