

- (void) loadVideoWithId: (NSString *) videoId {

    // For a full list of player parameters, see the documentation for the HTML5 player
    // at: https://developers.google.com/youtube/player_parameters?playerVersion=HTML5
    NSDictionary *playerVars = @{};
    self.youTubePlayerView.delegate = self;
    [self.youTubePlayerView loadWithVideoId:videoId playerVars:playerVars];

}

#pragma mark - YTPlayerViewDelegate

- (void) playerViewDidBecomeReady:(YTPlayerView *)playerView {
    if (playerView != self.youTubePlayerView) {
        return;
    }

    self.watchVideoButton.enabled = YES;
}

- (void) playerView:(YTPlayerView *)playerView didChangeToState:(YTPlayerState)state {
    switch (state) {
        case kYTPlayerStatePlaying:
        {
            [self videoDidStartPlaying];
            break;
        }
        case kYTPlayerStateEnded:
        {
            [self videoDidStopPlaying];
            break;
        }

        default:
            break;
    }
}

- (void) playerView:(YTPlayerView *)playerView didChangeToQuality:(YTPlaybackQuality)quality {
    if (playerView != self.youTubePlayerView) {
        return;
    }

    switch (quality) {
        case kYTPlaybackQualitySmall:
            DLog(@"YouTube player changed quality: Small");
            break;

        case kYTPlaybackQualityMedium:
            DLog(@"YouTube player changed quality: Medium");
            break;

        case kYTPlaybackQualityLarge:
            DLog(@"YouTube player changed quality: Large");
            break;

        case kYTPlaybackQualityHighRes:
            DLog(@"YouTube player changed quality: HighRes");
            break;

        case kYTPlaybackQualityHD720:
            DLog(@"YouTube player changed quality: HD720");
            break;

        case kYTPlaybackQualityHD1080:
            DLog(@"YouTube player changed quality: HD1080");
            break;

        case kYTPlaybackQualityUnknown:
            DLog(@"YouTube player changed quality: Unknown");
            break;

        default:
            break;
    }
}

- (void) playerView:(YTPlayerView *)playerView receivedError:(YTPlayerError)error {
    if (playerView != self.youTubePlayerView) {
        return;
    }

    switch (error) {
        case kYTPlayerErrorHTML5Error:
            DLog(@"YouTube player failed: HTML5 Error");
            break;

        case kYTPlayerErrorInvalidParam:
            DLog(@"YouTube player failed: Invalid param");
            break;

        case kYTPlayerErrorNotEmbeddable:
            DLog(@"YouTube player failed: Not embeddable");
            break;

        case kYTPlayerErrorVideoNotFound:
            DLog(@"YouTube player failed: Video not found");
            break;

        case kYTPlayerErrorUnknown:
            DLog(@"YouTube player failed: Unknown");
            break;

        default:
            break;
    }
}

- (void) videoDidStartPlaying {
    AppSpecificDelegate *appDelegate = (AppSpecificDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.interceptedHitTestDelegate = self;
    appDelegate.shouldDisplayLandscape = YES;

    if (!iOS7) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(moviePlayerWillExitFullScreen:)
                                                     name:@"UIMoviePlayerControllerWillExitFullscreenNotification"
                                                   object:nil];
    }
}

- (void) videoDidStopPlaying {
    AppSpecificDelegate *appDelegate = (AppSpecificDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.window.interceptedHitTestDelegate = nil;
    appDelegate.shouldDisplayLandscape = NO;

    self.messageLabel.text = @"First, confirm you have watched the video. Then enter and submit your ticket number to activate your wristband.";

    [self setViews:self.firstFormViews hidden:YES];
    [self setViews:self.secondFormViews hidden:NO];

    if (iOS7) {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void) moviePlayerWillExitFullScreen: (NSNotification *) notification {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self videoDidStopPlaying];
}

#pragma mark - FAWindowInterceptedTouchDelegate

- (void) window:(FAWindow *)window interceptedHitTest:(CGPoint)point withEvent:(UIEvent *)event {
    [self.youTubePlayerView pauseVideo];
    self.youTubeAlertView = [[UIAlertView alloc] initWithTitle: @"Sorry"
                                                       message: @"You must watch the video in its entirety in order to validate your wristband."
                                                      delegate: self
                                             cancelButtonTitle: @"Resume"
                                             otherButtonTitles: nil];
    [self.youTubeAlertView show];
}

#pragma mark - UIAlertViewDelegate

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {

    if (alertView == self.youTubeAlertView) {
        [self.youTubePlayerView playVideo];
    } else if (alertView == self.wristbandSuccessAlertView) {

        if (self.onboardingDelegate) {
            EZWristbandRegisterViewController *registerVC = [self registerViewController];

            if (registerVC != nil) {
                registerVC.ticketNumber = @(self.ticketNumberTextField.text.integerValue);
            }

            [self.onboardingDelegate onboardingViewControllerFinished:self didSkip:NO];
        }
    }
}

#pragma mark - IBAction

- (IBAction)watchVideoButtonPressed:(id)sender {

    [self.youTubePlayerView playVideo];
}
