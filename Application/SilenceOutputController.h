/*
 SilenceOutputController.h

 This file is part of Audirvana.

 Audirvana is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 */

#import <Cocoa/Cocoa.h>

@class AppController;

@interface SilenceOutputController : NSObject {
    NSPanel         *panel;
    NSPopUpButton   *sampleRatePopup;
    NSButton        *startButton;
    NSButton        *stopButton;
    NSTextField     *statusLabel;

    AppController   *appController;
    BOOL             isActive;
}

- (id)initWithAppController:(AppController*)controller;
- (void)showPanel;
- (void)setIsActive:(BOOL)active;
- (void)updateStatus:(NSString*)status;

@end
