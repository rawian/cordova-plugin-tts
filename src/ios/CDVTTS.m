/*
    Cordova Text-to-Speech Plugin
    https://github.com/vilic/cordova-plugin-tts
 
    by VILIC VANE
    https://github.com/vilic
 
    MIT License
*/

#import <Cordova/CDV.h>
#import <Cordova/CDVAvailability.h>
#import "CDVTTS.h"

@implementation CDVTTS

- (void)pluginInitialize {
    synthesizer = [AVSpeechSynthesizer new];
    synthesizer.delegate = self;
}

- (void)speechSynthesizer:(AVSpeechSynthesizer*)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance*)utterance {
    CDVPluginResult* result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    if (lastCallbackId) {
        [self.commandDelegate sendPluginResult:result callbackId:lastCallbackId];
        lastCallbackId = nil;
    } else {
        [self.commandDelegate sendPluginResult:result callbackId:callbackId];
        callbackId = nil;
    }
    
    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryAmbient 
      withOptions: 0 error: nil];
    [[AVAudioSession sharedInstance] setActive:YES withOptions: 0 error:nil];
}

- (void)speak:(CDVInvokedUrlCommand*)command {

    [[AVAudioSession sharedInstance] setActive:NO withOptions:0 error:nil];
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback
      withOptions:AVAudioSessionCategoryOptionDuckOthers error:nil];

    NSDictionary* options = [command.arguments objectAtIndex:0];
    
    NSString* text = [options objectForKey:@"text"];    
    NSString* voiceURI = [options objectForKey:@"voiceURI"];
    double rate = [[options objectForKey:@"rate"] doubleValue];  

    if (callbackId) {
        lastCallbackId = callbackId;
    }
    
    callbackId = command.callbackId;
    
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    if (!voiceURI || (id)voiceURI == [NSNull null]) {
        voiceURI = @"com.apple.ttsbundle.siri_male_en-US_compact";
    }
    
    if (!rate) {
        rate = 0.5;
    }
   
    AVSpeechUtterance* utterance = [[AVSpeechUtterance new] initWithString:text];
    
    utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier:voiceURI];
    utterance.rate = rate;
    utterance.pitchMultiplier = 1.0;
    utterance.volume = 1.0;
    [synthesizer speakUtterance:utterance];
}

- (void)stop:(CDVInvokedUrlCommand*)command {
    [synthesizer pauseSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
}

- (void)checkLanguage:(CDVInvokedUrlCommand *)command {
    NSArray *voices = [AVSpeechSynthesisVoice speechVoices];
    NSString *languages = @"";
    for (id voiceName in voices) {
        languages = [languages stringByAppendingString:@","];
        languages = [languages stringByAppendingString:[voiceName valueForKey:@"language"]];
    }
    if ([languages hasPrefix:@","] && [languages length] > 1) {
        languages = [languages substringFromIndex:1];
    }

    CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:languages];
    [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
}
@end
