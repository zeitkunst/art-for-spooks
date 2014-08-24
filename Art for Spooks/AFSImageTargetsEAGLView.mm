/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>
#import <sys/time.h>

#import <QCAR/QCAR.h>
#import <QCAR/State.h>
#import <QCAR/Tool.h>
#import <QCAR/Renderer.h>
#import <QCAR/TrackableResult.h>
#import <QCAR/VideoBackgroundConfig.h>
#import <QCAR/ImageTarget.h>

#import "AFSImageTargetsEAGLView.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"
#import "Quad.h"


//******************************************************************************
// *** OpenGL ES thread safety ***
//
// OpenGL ES on iOS is not thread safe.  We ensure thread safety by following
// this procedure:
// 1) Create the OpenGL ES context on the main thread.
// 2) Start the QCAR camera, which causes QCAR to locate our EAGLView and start
//    the render thread.
// 3) QCAR calls our renderFrameQCAR method periodically on the render thread.
//    The first time this happens, the defaultFramebuffer does not exist, so it
//    is created with a call to createFramebuffer.  createFramebuffer is called
//    on the main thread in order to safely allocate the OpenGL ES storage,
//    which is shared with the drawable layer.  The render (background) thread
//    is blocked during the call to createFramebuffer, thus ensuring no
//    concurrent use of the OpenGL ES context.
//
//******************************************************************************


namespace {
    // --- Data private to this unit ---

    // Teapot texture filenames
    const char* textureFilenames[] = {
        "DerSpiegel-media-34098_003.png",
        "Intercept-psychology-a-new-kind-of-sigdev_020.png",
        "Intercept-psychology-a-new-kind-of-sigdev_025.png",
        "building_texture.jpeg",
        "clouds-2.png"
    };
    
    NSMutableDictionary *textureDict = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *textureIDs = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableArray *shaderNames = [[[NSMutableArray alloc] init] autorelease];
    
    
    // Model scale factor
    const float kObjectScaleNormal = 72.0f; // old, should be removed
    const float kObjectScaleNormalx = 106.0f;
    const float kObjectScaleNormaly = 80.0f;
    
    // Tracking lost timeout
    const NSTimeInterval TRACKING_LOST_TIMEOUT = 2.0f;
    
    float texturePosition = -20.0;
    
    enum tagFOXACID_STATE {
        PRE_FOXACID,
        PLAYING_FOXACID,
        POST_FOXACID
    } foxacid_state;
    
    int foxacid_FramesPerSecond = 15;
    int foxacid_FramesPerRow = 4;
    int foxacid_FramesPerColumn = 5;
    int foxacid_Frames = 19;
    int foxacid_currentFrame = 0;
    float foxacid_preDelay = 2.0;
    float foxacid_postDelay = 2.0;
    
    
    
    // Current trackable
    NSMutableString *currentTrackable = [[[NSMutableString alloc] init] autorelease];
    
    // Video quad texture coordinates
    const GLfloat videoQuadTextureCoords[] = {
        0.0, 1.0,
        1.0, 1.0,
        1.0, 0.0,
        0.0, 0.0,
    };
    
    struct tagVideoData {
        // Needed to calculate whether a screen tap is inside the target
        QCAR::Matrix44F modelViewMatrix;
        
        // Trackable dimensions
        QCAR::Vec2F targetPositiveDimensions;
        
        // Currently active flag
        BOOL isActive;
    } videoData;
}


@interface AFSImageTargetsEAGLView (PrivateMethods)

- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end


@implementation AFSImageTargetsEAGLView

// You must implement this method, which ensures the view's underlying layer is
// of type CAEAGLLayer
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}


//------------------------------------------------------------------------------
#pragma mark - Lifecycle

- (id)initWithFrame:(CGRect)frame rootViewController:(AFSImageTargetsViewController *) rootViewController appSession:(SampleApplicationSession *) app
{
    self = [super initWithFrame:frame];
    
    if (self) {
        afsImageTargetsViewController = rootViewController;
        vapp = app;
        // Enable retina mode if available on this device
        if (YES == [vapp isRetinaDisplay]) {
            [self setContentScaleFactor:2.0f];
        }

        // Create the OpenGL ES context
        context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        
        // The EAGLContext must be set for each thread that wishes to use it.
        // Set it the first time this method is called (on the main thread)
        if (context != [EAGLContext currentContext]) {
            [EAGLContext setCurrentContext:context];
        }
        
        // Load all of the textures, assign IDs
        [self initTextureDict];
        [self loadTextureIDs];
        
        [currentTrackable setString:@""];
        
        // Set of possible shaders
        [shaderNames addObject:@"Simple"];
        [shaderNames addObject:@"DistortedTV"];
        
        // Setup video player helper
        videoPlayerHelper = [[VideoPlayerHelper alloc] initWithRootViewController:afsImageTargetsViewController];
        videoData.targetPositiveDimensions.data[0] = 0.0f;
        videoData.targetPositiveDimensions.data[1] = 0.0f;
        videoPlaybackTime = VIDEO_PLAYBACK_CURRENT_POSITION;
        
        // Load video
        if (NO == [videoPlayerHelper load:@"1984Macintosh.m4v" playImmediately:NO fromPosition:videoPlaybackTime]) {
            NSLog(@"Failed to load video file");
        }
        
        testingLabel = [self labelWithText:@"This is a test" yPosition: (CGFloat) 20.0];
        [testingLabel setBackgroundColor:[UIColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.25]];
        //[self addSubview:testingLabel];
    }
    
    return self;
}


- (void)initTextureDict {
    
    //[textureDict setValue:@"DerSpiegel-media-34098_003.png" forKey:@"Anchory"];
    [textureDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"DerSpiegel-media-34098_003.png"
                             } forKey:@"Anchory"];
    [textureDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"Intercept-psychology-a-new-kind-of-sigdev_020.png"} forKey:@"Facebook"];
    [textureDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"Intercept-psychology-a-new-kind-of-sigdev_025.png"} forKey:@"Woman"];
    [textureDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"Intercept-the-art-of-deception-training-for-a-new_034.png"} forKey:@"Buffalo"];
    [textureDict setValue:@{
                             @"shader": @"DistortedTV",
                             @"texture": @"Intercept-the-art-of-deception-training-for-a-new_021.png"} forKey:@"Bosch"];
    [textureDict setValue:@{
                            @"shader": @"DistortedTV",
                            @"texture": @""} forKey:@"1984"];
    [textureDict setValue:@{
                            @"shader": @"Animate_4x5",
                            @"texture": @"DerSpiegel-nsa-quantumtheory_002_sprites.png"} forKey:@"Foxacid"];
    [textureDict setValue:@{
                            @"shader": @"Simple",
                            @"texture": @"dollar_bill_obverse.png"} forKey:@"default"];
}

- (void)loadTextureIDs {
    for (NSString *key in textureDict) {
        NSDictionary *dict = [textureDict objectForKey:key];
        NSString *textureFilename = [dict valueForKey:@"texture"];
        
        // If no texture is set for this particular trackable, skip
        if ([textureFilename isEqualToString:@""]) {
            continue;
        }
        Texture* t = [[Texture alloc] initWithImageFile:[dict valueForKey:@"texture"]];

        GLuint textureID;
        glGenTextures(1, &textureID);
        [t setTextureID:textureID];
        glBindTexture(GL_TEXTURE_2D, textureID);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
        glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
        //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
        glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [t width], [t height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[t pngData]);
        [textureIDs setObject:t forKey:[dict valueForKey:@"texture"]];
    }
}

// From RosyWriter
- (UILabel *)labelWithText:(NSString *)text yPosition:(CGFloat)yPosition
{
	//CGFloat labelWidth = 200.0;
	//CGFloat labelHeight = 400.0;
    // TODO
    // Deal better with content scaling/retina displays than this hardcoded sample.
    // TODO
    // Need to deal with proper positioning, padding
    CGFloat labelHeight = self.bounds.size.height/2.0;
    CGFloat labelWidth = self.bounds.size.width/2.0;
	CGFloat xPosition = self.bounds.size.width - labelWidth - 10;
	//CGRect labelFrame = CGRectMake(xPosition, yPosition, labelWidth, labelHeight);
    CGRect labelFrame = CGRectMake(0, 0, labelWidth, labelHeight);
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
	[label setFont:[UIFont systemFontOfSize:36]];
    // TODO
    // Figure out how to set the following parameters in ios 7
    [label setLineBreakMode:NSLineBreakByWordWrapping];
    [label setTextAlignment:NSTextAlignmentJustified];
	[label setTextColor:[UIColor whiteColor]];
    [label setNumberOfLines:0];
	[label setBackgroundColor:[UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.25]];
	[[label layer] setCornerRadius: 4];
	[label setText:text];
    //[label setTransform:CGAffineTransformMakeRotation(-M_PI / 2)];
	
	return [label autorelease];
}

- (void) showMessage:(NSString *)message {
    [testingLabel setText:message];
}

- (void)dealloc
{
    [self deleteFramebuffer];
    
    // Tear down context
    if ([EAGLContext currentContext] == context) {
        [EAGLContext setCurrentContext:nil];
    }
    
    [context release];
    
    for (NSString *key in textureIDs) {
        [[textureIDs objectForKey:key] release];
    }
    
    [videoPlayerHelper release];

    [super dealloc];
}


- (void)finishOpenGLESCommands
{
    // Called in response to applicationWillResignActive.  The render loop has
    // been stopped, so we now make sure all OpenGL ES commands complete before
    // we (potentially) go into the background
    if (context) {
        [EAGLContext setCurrentContext:context];
        glFinish();
    }
}


- (void)freeOpenGLESResources
{
    // Called in response to applicationDidEnterBackground.  Free easily
    // recreated OpenGL ES resources
    [self deleteFramebuffer];
    glFinish();
}

- (void) updateTexturePosition {
    if (texturePosition >= 20.0) {
        texturePosition = -20.0;
    } else {
        texturePosition += 0.05;
    }
}

//------------------------------------------------------------------------------
#pragma mark - UIGLViewProtocol methods

// Draw the current frame using OpenGL
//
// This method is called by QCAR when it wishes to render the current frame to
// the screen.
//
// *** QCAR will call this method periodically on a background thread ***
- (void)renderFrameQCAR
{
    
    [self setFramebuffer];
    
    // Clear colour and depth buffers
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    // Render video background and retrieve tracking state
    QCAR::State state = QCAR::Renderer::getInstance().begin();
    QCAR::Renderer::getInstance().drawVideoBackground();
    
    glEnable(GL_DEPTH_TEST);
    // We must detect if background reflection is active and adjust the culling direction.
    // If the reflection is active, this means the pose matrix has been reflected as well,
    // therefore standard counter clockwise face culling will result in "inside out" models.

    glEnable(GL_CULL_FACE);

    glCullFace(GL_BACK);
    if(QCAR::Renderer::getInstance().getVideoBackgroundConfig().mReflection == QCAR::VIDEO_BACKGROUND_REFLECTION_ON)
        glFrontFace(GL_CW);  //Front camera
    else
        glFrontFace(GL_CCW); //Back camera
    
    NSString *trackableName;
    
    // ----- Synchronise data access -----
    [dataLock lock];
    
    // Assume video is inactive
    videoData.isActive = NO;
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        
        // Get the trackable
        const QCAR::TrackableResult* result = state.getTrackableResult(i);
        const QCAR::Trackable& trackable = result->getTrackable();
        QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        trackableName = [NSMutableString stringWithUTF8String:trackable.getName()];
        
        // Check if we have anything for this trackable in our dict
        if ([textureDict valueForKey:trackableName] == nil) {
            trackableName = @"default";
        }
        
        [self setCurrentTrackableWith:trackableName];
        
        // Here, we branch to different types of augmentations
        // Some are simple and just are texture replacements using different shader programs
        // Others do video playback or loading of models and particle systems
        
        // BEGIN 1984 TARGET AUGMENTATION
        if ([currentTrackable isEqualToString:@"1984"]){
            // Mark this video (target) as active
            videoData.isActive = YES;
            
            // Get the target size (used to determine if taps are within the target)
            if (0.0f == videoData.targetPositiveDimensions.data[0] ||
                0.0f == videoData.targetPositiveDimensions.data[1]) {
                const QCAR::ImageTarget& imageTarget = (const QCAR::ImageTarget&) trackable;
                
                videoData.targetPositiveDimensions = imageTarget.getSize();
                // The pose delivers the centre of the target, thus the dimensions
                // go from -width / 2 to width / 2, and -height / 2 to height / 2
                videoData.targetPositiveDimensions.data[0] /= 2.0f;
                videoData.targetPositiveDimensions.data[1] /= 2.0f;
            }
            
            // Get the current trackable pose
            const QCAR::Matrix34F& trackablePose = result->getPose();
            
            // This matrix is used to calculate the location of the screen tap
            videoData.modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(trackablePose);
            
            float aspectRatio;
            const GLvoid* texCoords;
            GLuint frameTextureID;
            BOOL displayVideoFrame = YES;
            
            // Retain value between calls
            static GLuint videoTextureID = {0};
            
            MEDIA_STATE currentStatus = [videoPlayerHelper getStatus];
            
            // --- INFORMATION ---
            // One could trigger automatic playback of a video at this point.  This
            // could be achieved by calling the play method of the VideoPlayerHelper
            // object if currentStatus is not PLAYING.  You should also call
            // getStatus again after making the call to play, in order to update the
            // value held in currentStatus.
            // --- END INFORMATION ---
            
            if (ERROR != currentStatus && NOT_READY != currentStatus && PLAYING != currentStatus) {
                // Play the video
                NSLog(@"Playing video with on-texture player");
                [videoPlayerHelper play:NO fromPosition:VIDEO_PLAYBACK_CURRENT_POSITION];
            } else {
                //NSLog(@"Should be playing...");
            }
            
            switch (currentStatus) {
                case PLAYING: {
                    // If the tracking lost timer is scheduled, terminate it
                    
                    if (nil != trackingLostTimer) {
                        // Timer termination must occur on the same thread on which
                        // it was installed
                        [self performSelectorOnMainThread:@selector(terminateTrackingLostTimer) withObject:nil waitUntilDone:YES];
                    }
                    
                    
                    // Upload the decoded video data for the latest frame to OpenGL
                    // and obtain the video texture ID
                    GLuint videoTexID = [videoPlayerHelper updateVideoData];
                    
                    if (0 == videoTextureID) {
                        videoTextureID = videoTexID;
                    }
                    
                    // Fallthrough
                }
                case PAUSED: {
                    if (0 == videoTextureID) {
                        // No video texture available, display keyframe
                        displayVideoFrame = NO;
                    }
                    else {
                        // Display the texture most recently returned from the call
                        // to [videoPlayerHelper updateVideoData]
                        frameTextureID = videoTextureID;
                    }
                    
                    break;
                }
                default:
                    videoTextureID = 0;
                    displayVideoFrame = NO;
                    break;
            }
            
            if (YES == displayVideoFrame) {
                // ---- Display the video frame -----
                aspectRatio = (float)[videoPlayerHelper getVideoHeight] / (float)[videoPlayerHelper getVideoWidth];
                texCoords = videoQuadTextureCoords;
            }
            else {
                // ----- Display the keyframe -----
                //Texture* t = augmentationTexture[OBJECT_KEYFRAME_1 + playerIndex];
                //frameTextureID = [t textureID];
                //aspectRatio = (float)[t height] / (float)[t width];
                texCoords = quadTexCoords;
            }
            
            // Get the current projection matrix
            QCAR::Matrix44F projMatrix = vapp.projectionMatrix;
            
            // If the current status is valid (not NOT_READY or ERROR), render the
            // video quad with the texture we've just selected
            if (NOT_READY != currentStatus) {
                // Convert trackable pose to matrix for use with OpenGL
                QCAR::Matrix44F modelViewMatrixVideo = QCAR::Tool::convertPose2GLMatrix(trackablePose);
                QCAR::Matrix44F modelViewProjectionVideo;
                
                //            SampleApplicationUtils::translatePoseMatrix(0.0f, 0.0f, videoData[playerIndex].targetPositiveDimensions.data[0],
                //                                             &modelViewMatrixVideo.data[0]);
                
                SampleApplicationUtils::scalePoseMatrix(videoData.targetPositiveDimensions.data[0],
                                                        videoData.targetPositiveDimensions.data[0] * aspectRatio,
                                                        videoData.targetPositiveDimensions.data[0],
                                                        &modelViewMatrixVideo.data[0]);
                
                SampleApplicationUtils::multiplyMatrix(projMatrix.data,
                                                       &modelViewMatrixVideo.data[0] ,
                                                       &modelViewProjectionVideo.data[0]);
                
                glUseProgram(shaderProgramID);
                
                glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, quadVertices);
                glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, quadNormals);
                glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, texCoords);
                
                glEnableVertexAttribArray(vertexHandle);
                glEnableVertexAttribArray(normalHandle);
                glEnableVertexAttribArray(textureCoordHandle);
                
                glActiveTexture(GL_TEXTURE0);
                glBindTexture(GL_TEXTURE_2D, frameTextureID);
                glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (GLfloat*)&modelViewProjectionVideo.data[0]);
                glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
                glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, quadIndices);
                
                glDisableVertexAttribArray(vertexHandle);
                glDisableVertexAttribArray(normalHandle);
                glDisableVertexAttribArray(textureCoordHandle);
                
                glUseProgram(0);
            }
            
        } // END 1984 TARGET AUGMENTATION
        else if ([currentTrackable isEqualToString:@"Foxacid"]) {
            [self animateFoxacid:[textureDict objectForKey:@"Foxacid"] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        } else {
            // Do our generic apply texture with the selected shader program, set in setCurrentTrackableWith:trackableName
            [self applyTextureWithTextureFile:[textureDict objectForKey:currentTrackable] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        }
        
    }
    
    // If a video is playing on texture and we have lost tracking, create a
    // timer on the main thread that will pause video playback after
    // TRACKING_LOST_TIMEOUT seconds
    if (nil == trackingLostTimer && NO == videoData.isActive && PLAYING == [videoPlayerHelper getStatus]) {
        [self performSelectorOnMainThread:@selector(createTrackingLostTimer) withObject:nil waitUntilDone:YES];
    }
    
    [dataLock unlock];
    // ----- End synchronise data access -----
    
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_CULL_FACE);
    
    glDisableVertexAttribArray(vertexHandle);
    glDisableVertexAttribArray(normalHandle);
    glDisableVertexAttribArray(textureCoordHandle);
    
    //[self performSelectorOnMainThread:@selector(showMessage:) withObject:@"TESTING!!! This is a test with long lines. Seeing if it will work." waitUntilDone:NO];
    QCAR::Renderer::getInstance().end();
    [self presentFramebuffer];
}

- (void)setCurrentTrackableWith:(NSString *)trackable {
    // Check if we're still tracking the same trackable; if not, update and reset time
    if (![trackable isEqualToString:currentTrackable]) {
        NSLog(@"DEBUG: Switching to trackable %@", trackable);
        [currentTrackable setString: trackable];
        [self resetTime];
        [self selectShaderWithName:[[textureDict objectForKey:currentTrackable] objectForKey:@"shader"]];
        
        if ([trackable isEqualToString:@"Foxacid"]) {
            foxacid_state = PRE_FOXACID;
            foxacid_currentFrame = 0;
        }
    }
}

- (void)resetTime {
    time = 0;
    angle = 0;
    previousTime = CACurrentMediaTime();
}

- (void)updateTime {
    time += 0.1;
    angle += 1.0;
    //foxacid_currentFrame += 1;
    if ((CACurrentMediaTime() - previousTime) >= (1.0/foxacid_FramesPerSecond) ) {
        foxacid_currentFrame += 1;
        foxacid_currentFrame = (foxacid_currentFrame)%foxacid_Frames;
        //foxacid_currentFrame = 0;
        previousTime = CACurrentMediaTime();
    }
    
    
}

- (void)updateFoxacidParams {
    time += 0.1;
    angle += 1.0;
    //foxacid_currentFrame += 1;
    switch (foxacid_state) {
        case PRE_FOXACID:
            if ((CACurrentMediaTime() - previousTime) >= foxacid_preDelay) {
                previousTime = CACurrentMediaTime();
                foxacid_state = PLAYING_FOXACID;
            }
            break;
        case PLAYING_FOXACID:
            if ((CACurrentMediaTime() - previousTime) >= (1.0/foxacid_FramesPerSecond) ) {
                foxacid_currentFrame += 1;
                //foxacid_currentFrame = (foxacid_currentFrame)%foxacid_Frames;
                //foxacid_currentFrame = 0;
                previousTime = CACurrentMediaTime();
            }

            //NSLog(@"Current frame: %d", foxacid_currentFrame);
            if (foxacid_currentFrame == foxacid_Frames) {
                //NSLog(@"RESETTING");
                previousTime = CACurrentMediaTime();
                foxacid_state = POST_FOXACID;
            }
            break;
        case POST_FOXACID:
            if ((CACurrentMediaTime() - previousTime) >= foxacid_postDelay) {
                previousTime = CACurrentMediaTime();
                foxacid_state = PRE_FOXACID;
                foxacid_currentFrame = 0;
            }
            break;
    }
}

- (void)animateFoxacid:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    // OpenGL 2
    QCAR::Matrix44F modelViewProjection;
    
    SampleApplicationUtils::translatePoseMatrix(0.0f, -1.0f, 0.0f, &modelViewMatrix.data[0]);
    SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormalx, kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
    
    
    // If sprite sheet is organized from right to left, then we need to offset by the last x position
    float currentRowPosition = 0.75 - (((foxacid_currentFrame) % foxacid_FramesPerRow) * 1.0f / foxacid_FramesPerRow);
    //NSLog(@"Current row position: %f", currentRowPosition);
    float currentColumnPosition = ((foxacid_currentFrame) / foxacid_FramesPerRow) * 1.0f / foxacid_FramesPerColumn;
    //NSLog(@"Current column position: %f", currentColumnPosition);
    //SampleApplicationUtils::translatePoseMatrix(currentRowPosition, currentColumnPosition, 0.0f, &modelViewMatrix.data[0]);
    //SampleApplicationUtils::scalePoseMatrix(1.0f/foxacid_FramesPerRow, 1/foxacid_FramesPerColumn, 1, &modelViewMatrix.data[0]);
    SampleApplicationUtils::translatePoseMatrix(-0.37, 0.07, 0.0f, &modelViewMatrix.data[0]);
    SampleApplicationUtils::scalePoseMatrix(0.58, 0.71, 1, &modelViewMatrix.data[0]);
    SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
    
    glUseProgram(shaderID);
    
    glVertexAttrib1f(frameRowHandle, currentRowPosition);
    glVertexAttrib1f(frameColumnHandle, currentColumnPosition);
    
    glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadVertices);
    glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadNormals);
    glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadTexCoords);
    
    glEnableVertexAttribArray(vertexHandle);
    glEnableVertexAttribArray(normalHandle);
    glEnableVertexAttribArray(textureCoordHandle);
    
    glActiveTexture(GL_TEXTURE0);
    
    NSString *textureFile = [textureInfo objectForKey:@"texture"];
    Texture* currentTexture = (Texture *)[textureIDs objectForKey:textureFile];
    glBindTexture(GL_TEXTURE_2D, currentTexture.textureID);
    
    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
    //glUniform1f(frameHandle, foxacid_currentFrame);
    //glUniform1f(frameRowHandle, currentRowPosition);
    //glUniform1f(frameColumnHandle, currentColumnPosition);
    glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
    [self updateFoxacidParams];
    glUniform1f(timeHandle, time);
    glUniform2fv(resolutionHandle, 1, resolution);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
    
    SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
}

- (void)applyTextureWithTextureFile:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    // OpenGL 2
    QCAR::Matrix44F modelViewProjection;
    
    SampleApplicationUtils::translatePoseMatrix(0.0f, -1.0f, 0.0f, &modelViewMatrix.data[0]);
    //SampleApplicationUtils::translatePoseMatrix(0, 0, 30.0, &modelViewMatrix.data[0]);
    //SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0, &modelViewMatrix.data[0]);
    SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormalx, kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
    //[self updateTexturePosition];
    
    SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
    
    glUseProgram(shaderID);
    
    glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadVertices);
    glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadNormals);
    glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadTexCoords);
    
    glEnableVertexAttribArray(vertexHandle);
    glEnableVertexAttribArray(normalHandle);
    glEnableVertexAttribArray(textureCoordHandle);
    
    glActiveTexture(GL_TEXTURE0);
    
    NSString *textureFile = [textureInfo objectForKey:@"texture"];
    Texture* currentTexture = (Texture *)[textureIDs objectForKey:textureFile];
    glBindTexture(GL_TEXTURE_2D, currentTexture.textureID);
    
    glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
    glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
    [self updateTime];
    glUniform1f(timeHandle, time);
    glUniform2fv(resolutionHandle, 1, resolution);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
    
    SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
}

// Create the tracking lost timer
- (void)createTrackingLostTimer
{
    trackingLostTimer = [NSTimer scheduledTimerWithTimeInterval:TRACKING_LOST_TIMEOUT target:self selector:@selector(trackingLostTimerFired:) userInfo:nil repeats:NO];
}

// Terminate the tracking lost timer
- (void)terminateTrackingLostTimer
{
    [trackingLostTimer invalidate];
    trackingLostTimer = nil;
}


// Tracking lost timer fired, pause video playback
- (void)trackingLostTimerFired:(NSTimer*)timer
{
    // Tracking has been lost for TRACKING_LOST_TIMEOUT seconds, pause playback
    // (we can safely do this on all our VideoPlayerHelpers objects)
    [videoPlayerHelper pause];
    trackingLostTimer = nil;
}


//------------------------------------------------------------------------------
#pragma mark - OpenGL ES management

- (void)selectShaderWithName: (NSString *)shaderName
{
    NSLog(@"DEBUG: Shader name: %@", shaderName);
    shaderProgramID = [SampleApplicationShaderUtils
                       createProgramWithVertexShaderFileName:[NSString stringWithFormat:@"%@.vertsh", shaderName]
                       fragmentShaderFileName:[NSString stringWithFormat:@"%@.fragsh", shaderName]];
    
    //distortedTVShaderProgramID = [SampleApplicationShaderUtils createProgramWithVertexShaderFileName:@"DistortedTV.vertsh"
    //                                                                          fragmentShaderFileName:@"DistortedTV.fragsh"];
    if (0 < shaderProgramID) {
        vertexHandle = glGetAttribLocation(shaderProgramID, "vertexPosition");
        normalHandle = glGetAttribLocation(shaderProgramID, "vertexNormal");
        textureCoordHandle = glGetAttribLocation(shaderProgramID, "vertexTexCoord");
        frameRowHandle = glGetAttribLocation(shaderProgramID, "frameRow");
        frameColumnHandle = glGetAttribLocation(shaderProgramID, "frameColumn");
        mvpMatrixHandle = glGetUniformLocation(shaderProgramID, "modelViewProjectionMatrix");
        texSampler2DHandle  = glGetUniformLocation(shaderProgramID,"texSampler2D");
        resolutionHandle = glGetUniformLocation(shaderProgramID, "resolution");
        timeHandle = glGetUniformLocation(shaderProgramID, "time");
        time = 0.0;
        CGRect rect = [self frame];
        resolution[0] = rect.size.width;
        resolution[1] = rect.size.height;
    }
    else {
        NSLog(@"Could not initialise augmentation shader");
    }
}


- (void)createFramebuffer
{
    if (context) {
        // Create default framebuffer object
        glGenFramebuffers(1, &defaultFramebuffer);
        glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
        
        // Create colour renderbuffer and allocate backing store
        glGenRenderbuffers(1, &colorRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
        
        // Allocate the renderbuffer's storage (shared with the drawable object)
        [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:(CAEAGLLayer*)self.layer];
        GLint framebufferWidth;
        GLint framebufferHeight;
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &framebufferWidth);
        glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &framebufferHeight);
        
        // Create the depth render buffer and allocate storage
        glGenRenderbuffers(1, &depthRenderbuffer);
        glBindRenderbuffer(GL_RENDERBUFFER, depthRenderbuffer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, framebufferWidth, framebufferHeight);
        
        // Attach colour and depth render buffers to the frame buffer
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, colorRenderbuffer);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, depthRenderbuffer);
        
        // Leave the colour render buffer bound so future rendering operations will act on it
        glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    }
}


- (void)deleteFramebuffer
{
    if (context) {
        [EAGLContext setCurrentContext:context];
        
        if (defaultFramebuffer) {
            glDeleteFramebuffers(1, &defaultFramebuffer);
            defaultFramebuffer = 0;
        }
        
        if (colorRenderbuffer) {
            glDeleteRenderbuffers(1, &colorRenderbuffer);
            colorRenderbuffer = 0;
        }
        
        if (depthRenderbuffer) {
            glDeleteRenderbuffers(1, &depthRenderbuffer);
            depthRenderbuffer = 0;
        }
    }
}


- (void)setFramebuffer
{
    
    // The EAGLContext must be set for each thread that wishes to use it.  Set
    // it the first time this method is called (on the render thread)
    if (context != [EAGLContext currentContext]) {
        [EAGLContext setCurrentContext:context];
    }
    
    if (!defaultFramebuffer) {
        // Perform on the main thread to ensure safe memory allocation for the
        // shared buffer.  Block until the operation is complete to prevent
        // simultaneous access to the OpenGL context
        [self performSelectorOnMainThread:@selector(createFramebuffer) withObject:self waitUntilDone:YES];
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFramebuffer);
}


- (BOOL)presentFramebuffer
{
    // setFramebuffer must have been called before presentFramebuffer, therefore
    // we know the context is valid and has been set for this (render) thread
    
    // Bind the colour render buffer and present it
    glBindRenderbuffer(GL_RENDERBUFFER, colorRenderbuffer);
    
    return [context presentRenderbuffer:GL_RENDERBUFFER];
}



@end
