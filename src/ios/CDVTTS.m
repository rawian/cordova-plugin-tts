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

    if (callbackId) {
        lastCallbackId = callbackId;
    }
    
    callbackId = command.callbackId;
    
    [synthesizer stopSpeakingAtBoundary:AVSpeechBoundaryImmediate];
    
    NSDictionary* options = [command.arguments objectAtIndex:0];
    
    NSString* text = [options objectForKey:@"text"];
    NSString* locale = [options objectForKey:@"locale"];
    NSString* voiceType = [options objectForKey:@"voiceType"];
    NSString* voiceUri = [options objectsForKey:@"voiceURI"];

    double rate = [[options objectForKey:@"rate"] doubleValue];
    NSString* voice;
    
    if (!locale || (id)locale == [NSNull null]) {
        locale = @"en-US";
    }
    
    if (!rate) {
        rate = 1.0;
    }
    
    if([voiceType isEqualToString:@"Male"]){
        voice = @"com.apple.ttsbundle.siri_male_en-US_compact";
    }
    else{
        voice = @"com.apple.ttsbundle.siri_female_en-US_compact";
    }
    
    AVSpeechUtterance* utterance = [[AVSpeechUtterance new] initWithString:text];
    //utterance.voice = [AVSpeechSynthesisVoice voiceWithLanguage:locale];
    // utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier:voice];
    utterance.voice = [AVSpeechSynthesisVoice voiceWithIdentifier:voiceURI];
    // Rate expression adjusted manually for a closer match to other platform.
    //utterance.rate = (AVSpeechUtteranceMinimumSpeechRate * 1.5 + AVSpeechUtteranceDefaultSpeechRate) / 2.25 * rate * rate;
    // workaround for https://github.com/vilic/cordova-plugin-tts/issues/21
    //if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 9.0) {
       //utterance.rate = utterance.rate * 2;
       // see http://stackoverflow.com/questions/26097725/avspeechuterrance-speed-in-ios-8
    //}
    utterance.rate = 0.45;
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