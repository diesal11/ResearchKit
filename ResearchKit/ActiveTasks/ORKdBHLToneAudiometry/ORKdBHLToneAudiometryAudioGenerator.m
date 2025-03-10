/*
 Copyright (c) 2015, Shazino SAS. All rights reserved.
 Copyright (c) 2018, Apple Inc. All rights reserved.
 
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
 
 1.  Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.
 
 2.  Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation and/or
 other materials provided with the distribution.
 
 3.  Neither the name of the copyright holder(s) nor the names of any contributors
 may be used to endorse or promote products derived from this software without
 specific prior written permission. No license is granted to the trademarks of
 the copyright holders even if such marks are included in this software.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 
 ---
 
 This software is based on the original source by Matt Gallagher.
 http://www.cocoawithlove.com/2010/10/ios-tone-generator-introduction-to.html
 
 Copyright (c) 2009-2011 Matt Gallagher. All rights reserved.
 
 This software is provided 'as-is', without any express or implied warranty. In
 no event will the authors be held liable for any damages arising from the use
 of this software. Permission is granted to anyone to use this software for any
 purpose, including commercial applications, and to alter it and redistribute it
 freely, subject to the following restrictions:
 
 1. The origin of this software must not be misrepresented; you must not claim
 that you wrote the original software. If you use this software in a product,
 an acknowledgment in the product documentation would be appreciated but is
 not required.
 2. Altered source versions must be plainly marked as such, and must not be
 misrepresented as being the original software.
 3. This notice may not be removed or altered from any source distribution.
 */

#if TARGET_OS_IOS


#import "ORKdBHLToneAudiometryAudioGenerator.h"

@import AudioToolbox;

typedef NSString * ORKVolumeCurveFilename NS_STRING_ENUM;
ORKVolumeCurveFilename const ORKVolumeCurveFilenameAirPods = @"volume_curve_AIRPODS";
ORKVolumeCurveFilename const ORKVolumeCurveFilenameAirPodsGen3 = @"volume_curve_AIRPODSV3";
ORKVolumeCurveFilename const ORKVolumeCurveFilenameAirPodsPro = @"volume_curve_AIRPODSPRO";
ORKVolumeCurveFilename const ORKVolumeCurveFilenameAirPodsProGen2 = @"volume_curve_AIRPODSPROV2";
ORKVolumeCurveFilename const ORKVolumeCurveFilenameAirPodsMax = @"volume_curve_AIRPODSMAX";
ORKVolumeCurveFilename const ORKVolumeCurveFilenameWired = @"volume_curve_WIRED";

NSString * const frequencydBSPLBaseFilename = @"frequency_dBSPL_%@";
NSString * const retsplBaseFilename = @"retspl_%@";
NSString * const filenameExtension = @"plist";

@interface ORKdBHLToneAudiometryAudioGenerator () {
@public
    AudioComponentInstance _toneUnit;
    AUGraph _mGraph;
    AUNode _outputNode;
    AUNode _mixerNode;
    AudioUnit _mMixer;
    double _frequency;
    unsigned long _thetaIndex;
    ORKAudioChannel _activeChannel;
    BOOL _playsStereo;
    BOOL _rampUp;
    double _fadeInFactor;
    double _globaldBHL;
    NSNumber *_amplitudeGain;
    NSTimeInterval _fadeInDuration;
    NSDictionary *_sensitivityPerFrequency;
    NSDictionary *_volumeCurve;
    NSDictionary *_retspl;
    int _lastNodeInput;
}

- (NSNumber *)dbHLtoAmplitude: (double)dbHL atFrequency:(double)frequency;

@end

const double ORKdBHLSineWaveToneGeneratorSampleRateDefault = 44100.0f;

static OSStatus ORKdBHLAudioGeneratorRenderTone(void *inRefCon,
                                                AudioUnitRenderActionFlags *ioActionFlags,
                                                const AudioTimeStamp         *inTimeStamp,
                                                UInt32                     inBusNumber,
                                                UInt32                     inNumberFrames,
                                                AudioBufferList             *ioData) {
    // Get the tone parameters out of the view controller
    ORKdBHLToneAudiometryAudioGenerator *audioGenerator = (__bridge ORKdBHLToneAudiometryAudioGenerator *)inRefCon;
    double amplitude;

    amplitude = [audioGenerator->_amplitudeGain doubleValue];
    
    double theta_increment = audioGenerator->_frequency / ORKdBHLSineWaveToneGeneratorSampleRateDefault;
    unsigned long theta_index = audioGenerator->_thetaIndex;

    double fadeInFactor = audioGenerator->_fadeInFactor;
    
    // This is a mono tone generator so we only need the first buffer
    Float32 *bufferActive    = (Float32 *)ioData->mBuffers[audioGenerator->_activeChannel].mData;
    Float32 *bufferNonActive = (Float32 *)ioData->mBuffers[1 - audioGenerator->_activeChannel].mData;
        
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
        if (audioGenerator->_rampUp) {
            fadeInFactor += 1.0 / (ORKdBHLSineWaveToneGeneratorSampleRateDefault * audioGenerator->_fadeInDuration);
            if (fadeInFactor >= 1) {
                fadeInFactor = 1;
            }
        } else {
            fadeInFactor -= 1.0 / (ORKdBHLSineWaveToneGeneratorSampleRateDefault * audioGenerator->_fadeInDuration);
            if (fadeInFactor <= 0) {
                fadeInFactor = 0;
            }
        }
        
        double theta = theta_index * theta_increment;
        double bufferValue = sin(theta * 2.0 * M_PI) * amplitude * pow(10, 2.0 * fadeInFactor - 2);
        theta_index++;
        
        bufferActive[frame] = bufferValue;
        if (audioGenerator->_playsStereo) {
            bufferNonActive[frame] = bufferValue;
        } else {
            bufferNonActive[frame] = 0;
        }
    }
    
    // Store the thetaIndex back in the view controller
    audioGenerator->_thetaIndex = theta_index;
    audioGenerator->_fadeInFactor = fadeInFactor;
    
    return noErr;
}

static OSStatus ORKdBHLAudioGeneratorZeroTone(void *inRefCon,
                                             AudioUnitRenderActionFlags *ioActionFlags,
                                             const AudioTimeStamp         *inTimeStamp,
                                             UInt32                     inBusNumber,
                                             UInt32                     inNumberFrames,
                                             AudioBufferList             *ioData) {
    // Get the tone parameters out of the view controller
    ORKdBHLToneAudiometryAudioGenerator *audioGenerator = (__bridge ORKdBHLToneAudiometryAudioGenerator *)inRefCon;
 
    // This is a mono tone generator so we only need the first buffer
    Float32 *bufferActive    = (Float32 *)ioData->mBuffers[audioGenerator->_activeChannel].mData;
    Float32 *bufferNonActive = (Float32 *)ioData->mBuffers[1 - audioGenerator->_activeChannel].mData;
    
    // Generate the samples
    for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
        double bufferValue = 0;
        bufferActive[frame] = bufferValue;
        bufferNonActive[frame] = bufferValue;
    }

    return noErr;
}

@implementation ORKdBHLToneAudiometryAudioGenerator

- (instancetype)initForHeadphoneType:(ORKHeadphoneTypeIdentifier)headphoneType {
    self = [super init];
    if (self) {
        _lastNodeInput = 0;
        
        NSString *headphoneTypeUppercased = [headphoneType uppercaseString];
        ORKHeadphoneTypeIdentifier headphoneTypeIdentifier;
        ORKVolumeCurveFilename volumeCurveFilename;
        
        if ([headphoneTypeUppercased isEqualToString:ORKHeadphoneTypeIdentifierAirPodsGen1] ||
            [headphoneTypeUppercased isEqualToString:ORKHeadphoneTypeIdentifierAirPodsGen2]) {
            headphoneTypeIdentifier = ORKHeadphoneTypeIdentifierAirPods;
            volumeCurveFilename = ORKVolumeCurveFilenameAirPods;
        } else if ([headphoneTypeUppercased isEqualToString:ORKHeadphoneTypeIdentifierAirPodsGen3]) {
            headphoneTypeIdentifier = ORKHeadphoneTypeIdentifierAirPodsGen3;
            volumeCurveFilename = ORKVolumeCurveFilenameAirPodsGen3;
        } else if ([headphoneTypeUppercased isEqualToString:ORKHeadphoneTypeIdentifierAirPodsPro]) {
            headphoneTypeIdentifier = ORKHeadphoneTypeIdentifierAirPodsPro;
            volumeCurveFilename = ORKVolumeCurveFilenameAirPodsPro;
        } else if ([headphoneTypeUppercased isEqualToString:ORKHeadphoneTypeIdentifierAirPodsProGen2]) {
            headphoneTypeIdentifier = ORKHeadphoneTypeIdentifierAirPodsProGen2;
            volumeCurveFilename = ORKVolumeCurveFilenameAirPodsProGen2;
        } else if ([headphoneTypeUppercased isEqualToString:ORKHeadphoneTypeIdentifierAirPodsMax]) {
            headphoneTypeIdentifier = ORKHeadphoneTypeIdentifierAirPodsMax;
            volumeCurveFilename = ORKVolumeCurveFilenameAirPodsMax;
        } else if ([headphoneTypeUppercased isEqualToString:ORKHeadphoneTypeIdentifierEarPods]) {
            headphoneTypeIdentifier = ORKHeadphoneTypeIdentifierEarPods;
            volumeCurveFilename = ORKVolumeCurveFilenameWired;
        } else {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"A valid headphone route identifier must be provided" userInfo:nil];
        }
        
        _sensitivityPerFrequency = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:frequencydBSPLBaseFilename, headphoneTypeIdentifier]  ofType:filenameExtension]];

        _retspl = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:[NSString stringWithFormat:retsplBaseFilename, headphoneTypeIdentifier] ofType:filenameExtension]];
        
        _volumeCurve = [NSDictionary dictionaryWithContentsOfFile:[[NSBundle bundleForClass:[self class]] pathForResource:volumeCurveFilename ofType:filenameExtension]];
        
        [self setupGraph];
    }
    return self;
}

- (void)dealloc {
    if (_mGraph) {
        int nodeInput = (_lastNodeInput % 2) + 1;
        AUGraphDisconnectNodeInput(_mGraph, _mixerNode, nodeInput);
        AUGraphUpdate(_mGraph, NULL);
        AUGraphStop(_mGraph);
        AUGraphUninitialize(_mGraph);
        _mGraph = nil;
    }
    
    _mMixer = nil;
}

- (void)playSoundAtFrequency:(double)playFrequency
                   onChannel:(ORKAudioChannel)playChannel
                        dBHL:(double)dBHL {
    _frequency = playFrequency;
    _activeChannel = playChannel;
    _fadeInFactor = 0;
    _fadeInDuration = 0.2;
    _rampUp = YES;
    _globaldBHL = dBHL;
    _thetaIndex = 0;
    
    [self play];
    
}

- (void)setupGraph {
    if (!_mGraph) {
        NewAUGraph(&_mGraph);
        AudioComponentDescription mixer_desc;
        mixer_desc.componentType = kAudioUnitType_Mixer;
        mixer_desc.componentSubType = kAudioUnitSubType_SpatialMixer;
        mixer_desc.componentFlags = 0;
        mixer_desc.componentFlagsMask = 0;
        mixer_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        
        AudioComponentDescription output_desc;
        output_desc.componentType = kAudioUnitType_Output;
        output_desc.componentSubType = kAudioUnitSubType_RemoteIO;
        output_desc.componentFlags = 0;
        output_desc.componentFlagsMask = 0;
        output_desc.componentManufacturer = kAudioUnitManufacturer_Apple;
        
        AUGraphAddNode(_mGraph, &output_desc, &_outputNode);
        AUGraphAddNode(_mGraph, &mixer_desc, &_mixerNode );
        
        AUGraphConnectNodeInput(_mGraph, _mixerNode, 0, _outputNode, 0);
        
        AUGraphOpen(_mGraph);
        AUGraphNodeInfo(_mGraph, _mixerNode, NULL, &_mMixer);
        
        UInt32 numbuses = 3;
        UInt32 size = sizeof(numbuses);
        AudioUnitSetProperty(_mMixer, kAudioUnitProperty_ElementCount, kAudioUnitScope_Input, 0, &numbuses, size);
        
        AudioStreamBasicDescription desc;
        for (int i = 0; i < numbuses; ++i) {
            AURenderCallbackStruct renderCallbackStruct;
            renderCallbackStruct.inputProcRefCon = (__bridge void *)(self);
            
            if (i == 0) {
                renderCallbackStruct.inputProc = ORKdBHLAudioGeneratorZeroTone;
                AUGraphSetNodeInputCallback(_mGraph, _mixerNode, 0, &renderCallbackStruct);
            }
            size = sizeof(desc);
            AudioUnitGetProperty(  _mMixer,
                                    kAudioUnitProperty_StreamFormat,
                                    kAudioUnitScope_Input,
                                    i,
                                    &desc,
                                    &size);
            memset (&desc, 0, sizeof (desc));
            const int four_bytes_per_float = 4;
            const int eight_bits_per_byte = 8;
            
            desc.mSampleRate = ORKdBHLSineWaveToneGeneratorSampleRateDefault;
            desc.mFormatID = kAudioFormatLinearPCM;
            desc.mFormatFlags = kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
            desc.mBytesPerPacket = four_bytes_per_float;
            desc.mFramesPerPacket = 1;
            desc.mBytesPerFrame = four_bytes_per_float;
            desc.mChannelsPerFrame = 2;
            desc.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;
            
            AudioUnitSetProperty(_mMixer,
                                 kAudioUnitProperty_StreamFormat,
                                 kAudioUnitScope_Input,
                                 i,
                                 &desc,
                                 sizeof(desc));
            
            AUSpatialMixerOutputType outputType = kSpatialMixerOutputType_Headphones;
            AudioUnitSetProperty(_mMixer,
                                 kAudioUnitProperty_SpatialMixerOutputType,
                                 kAudioUnitScope_Global,
                                 i,
                                 &outputType,
                                 sizeof(outputType));
            
            AUSpatializationAlgorithm stereoPassThrough = kSpatializationAlgorithm_StereoPassThrough;
            AudioUnitSetProperty(_mMixer,
                                 kAudioUnitProperty_SpatializationAlgorithm,
                                 kAudioUnitScope_Input,
                                 i,
                                 &stereoPassThrough,
                                 sizeof(stereoPassThrough));
            
            UInt32 bypass = kSpatialMixerSourceMode_Bypass;
            AudioUnitSetProperty(_mMixer,
                                 kAudioUnitProperty_SpatialMixerSourceMode,
                                 kAudioUnitScope_Input,
                                 i,
                                 &bypass,
                                 sizeof(bypass));
        }

        AudioUnitSetProperty(_mMixer,
                             kAudioUnitProperty_StreamFormat,
                             kAudioUnitScope_Output,
                             0,
                             &desc,
                             sizeof(desc));
        
        AUGraphInitialize(_mGraph);
        AUGraphStart(_mGraph);
    }
}

- (void)play {
    _amplitudeGain = [self dbHLtoAmplitude:_globaldBHL atFrequency:_frequency];
    AURenderCallbackStruct renderCallbackStruct;
    renderCallbackStruct.inputProcRefCon = (__bridge void *)(self);
    renderCallbackStruct.inputProc = ORKdBHLAudioGeneratorRenderTone;
    _lastNodeInput += 1;
    int connect = 0;
    int disconnect = 0;
    if ((_lastNodeInput % 2) == 0) {
        connect = 1;
        disconnect = 2;
    } else {
        connect = 2;
        disconnect = 1;
    }
    AUGraphDisconnectNodeInput(_mGraph, _mixerNode, disconnect);
    AUGraphSetNodeInputCallback(_mGraph, _mixerNode, connect, &renderCallbackStruct);
    AUGraphUpdate(_mGraph, NULL);
}

- (void)stop {
    if (_mGraph) {
        _rampUp = NO;
        int nodeInput = (_lastNodeInput % 2) + 1;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(_fadeInDuration * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            if (_mGraph) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    AUGraphDisconnectNodeInput(_mGraph, _mixerNode, nodeInput);
                    AUGraphUpdate(_mGraph, NULL);
                }); 
            }
        });
    }
}

- (double)dBToAmplitude:(double)dB {
    return (powf(10, 0.05 * dB));
}

- (float)getCurrentSystemVolume {
    return [[AVAudioSession sharedInstance] outputVolume];
}


- (NSNumber *)dbHLtoAmplitude: (double)dbHL atFrequency:(double)frequency {
    NSDecimalNumber *dBSPL =  [NSDecimalNumber decimalNumberWithString:_sensitivityPerFrequency[[NSString stringWithFormat:@"%.0f",frequency]]];

    // get current volume
    float currentVolume = [self getCurrentSystemVolume];
    
    currentVolume = (int)(currentVolume / 0.0625) * 0.0625;
    
    // check in volume curve table for offset
    NSDecimalNumber *offsetDueToVolume = [NSDecimalNumber decimalNumberWithString:_volumeCurve[[NSString stringWithFormat:@"%.4f",currentVolume]]];
    
    NSDecimalNumber *updated_dBSPLForVolumeCurve = [dBSPL decimalNumberByAdding:offsetDueToVolume];
    
    NSDecimalNumber *dBFSCalibration = [NSDecimalNumber decimalNumberWithString:@"30"];
    
    NSDecimalNumber *updated_dBSPLFor_dBFS = [updated_dBSPLForVolumeCurve decimalNumberByAdding:dBFSCalibration];
    
    NSDecimalNumber *baselinedBSPL = [NSDecimalNumber decimalNumberWithString:_retspl[[NSString stringWithFormat:@"%.0f",frequency]]];
    
    NSDecimalNumber *tempdBHL = [NSDecimalNumber decimalNumberWithString:[NSString stringWithFormat:@"%f", dbHL]];
    NSDecimalNumber *attenuationOffset = [baselinedBSPL decimalNumberByAdding:tempdBHL];

    NSDecimalNumber *attenuation = [attenuationOffset decimalNumberBySubtracting:updated_dBSPLFor_dBFS];

    // if the signal starts clipping
    if ([attenuation doubleValue] >= -1) {
        if (self.delegate && [self.delegate respondsToSelector:@selector(toneWillStartClipping)]) {
            [self.delegate toneWillStartClipping];
            return nil;
        }
    }
    
    double linearAttenuation = [self dBToAmplitude:attenuation.doubleValue];
    
    return [NSNumber numberWithDouble:linearAttenuation];
    
}

@end


#endif
