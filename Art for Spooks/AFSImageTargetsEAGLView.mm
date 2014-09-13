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
#import <QCAR/TrackerManager.h>
#import <QCAR/ImageTracker.h>

#import "AFSImageTargetsEAGLView.h"
#import "AFSImageTargetsViewController.h"
#import "AFSCardEmitterObject.h"
#import "AFSCardParticle.h"
#import "Texture.h"
#import "SampleApplicationUtils.h"
#import "SampleApplicationShaderUtils.h"
#import "Teapot.h"
#import "Quad.h"
#import "card.h"
#import "skymapTest.h"
#import "curvedDisplay.h"


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

static CGFloat DegreesToRadians(CGFloat degrees) {return degrees * M_PI / 180;};

namespace {
    // --- Data private to this unit ---
    
    NSMutableDictionary *augmentationDict = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableDictionary *textureIDs = [[[NSMutableDictionary alloc] init] autorelease];
    NSMutableArray *shaderNames = [[[NSMutableArray alloc] init] autorelease];
    
    
    // Model scale factor
    const float kObjectScaleNormal = 72.0f; // old, should be removed
    const float kCardsScaleNormal = 35.0f;
    const float kObjectScaleNormalx = 106.0f;
    const float kObjectScaleNormaly = 80.0f;
    
    // Tracking lost timeout
    const NSTimeInterval TRACKING_LOST_TIMEOUT = 2.0f;
    
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
    
    enum tagDOLPHIN_STATE {
        PRE_DOLPHIN,
        PLAYING_DOLPHIN,
        POST_DOLPHIN
    } dolphin_state;

    int dolphin_FramesPerSecond = 15;
    int dolphin_FramesPerRow = 8;
    int dolphin_FramesPerColumn = 8;
    int dolphin_Frames = 40;
    int dolphin_currentFrame = 0;
    float dolphin_preDelay = 2.0;
    float dolphin_postDelay = 2.0;

    
    enum tagBLURREDFACES_STATE {
        PRE_CAPTURE_FACE,
        SETUP_CAPTURE_FACE,
        CAPTURE_FACE,
        PRE_AUGMENT_FACE,
        AUGMENT_FACE
    } blurredFaces_state;
    float blurredFaces_preDelay = 2.0;
    float blurredFaces_preAlphaDelay = 5.0;
    float blurredFaces_captureDelay = 10.0;
    GLint defaultFBO;
    GLuint facesFBOHandle;
    GLuint facesDepthBuffer;
    GLuint facesFBOTexture;
    int facesFBOWidth;
    int facesFBOHeight;
    float eyeBoxQuadVertices[4*3] = {0};

    
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
    
    
    // Phantasmagoria Parameters
    //NSArray *phTextures = @[@"phantasmagoria003.png", @"phantasmagoria002.png", @"phantasmagoria001.png"];
    NSArray *phTextures = @[@"phantasmagoria002.png", @"phantasmagoria001.png"];
    
    float phP0MinX = -2.0;
    //float phP0MaxX = -0.5;
    float phP0MinY = -2.0;
    float phP0MaxY = 2.0;
    
    float phP1MinOffsetX = -2.0;
    float phP1MaxOffsetX = 2.0;
    float phP1MinOffsetY = -2.0;
    float phP1MaxOffsetY = 2.0;

    float phP2MinOffsetX = -2.0;
    float phP2MaxOffsetX = 2.0;
    float phP2MinOffsetY = -2.0;
    float phP2MaxOffsetY = 2.0;
    
    //float phP3MinX = 0.5;
    float phP3MaxX = 2.0;
    float phP3MinY = -2.0;
    float phP3MaxY = 2.0;
    
    float phTimeOffset[NUM_PHANTASMAGORIA_TEXTURES];
    float phTime[NUM_PHANTASMAGORIA_TEXTURES];
    float phTimeOffsetMin = 0.003;
    float phTimeOffsetMax = 0.009;
    
    float phP[NUM_PHANTASMAGORIA_TEXTURES][4][2];
    float phScale[NUM_PHANTASMAGORIA_TEXTURES][2];
    float phCurrentPos[NUM_PHANTASMAGORIA_TEXTURES][2];

    
    // RabbitDuck parameters
    float rdDeltaMagnitude = 5.0;
    float rdDelta;
    float rdXPos;
    float rdYPos;
    float rdFramesPerSecond = 30.0;
    
    // Card Emitter parameters
    AFSCardEmitterObject *emitter;
}


@interface AFSImageTargetsEAGLView (PrivateMethods)

- (void)createFramebuffer;
- (void)deleteFramebuffer;
- (void)setFramebuffer;
- (BOOL)presentFramebuffer;

@end

@interface AFSImageTargetsEAGLView ()
@property (nonatomic) CGRect eaglFrame;
@property (nonatomic) BOOL isUsingFrontFacingCamera;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *videoPreviewLayer;
@property (nonatomic, strong) AVCaptureVideoDataOutput *videoDataOutput;
@property (nonatomic) dispatch_queue_t videoDataOutputQueue;
@property (nonatomic, strong) UIImage *borderImage;
@property (nonatomic, strong) CIDetector *faceDetector;
@property (strong, nonatomic) CIContext *cicontext;
@property (strong) CIImage *currentFrontImage;
@property (nonatomic) CGRect faceRect;
@property (nonatomic) CGPoint leftEyePoint;
@property (nonatomic) CGPoint rightEyePoint;

@end


@implementation AFSImageTargetsEAGLView

//@synthesize videoPreviewLayer = _videoPreviewLayer;

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
        self.eaglFrame = frame;
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
        [self initAugmentationDict];
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
        
        // Create our face detector for BlurredFaces
        NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
        self.faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
        
    }
    
    return self;
}


- (void)initAugmentationDict {
    
    /*
     * AUGMENTATIONS
     */
    [augmentationDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"DerSpiegel-media-34098_003.png"
                             } forKey:@"Anchory"];
    [augmentationDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"Intercept-psychology-a-new-kind-of-sigdev_020.png"} forKey:@"Facebook"];
    [augmentationDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"Intercept-psychology-a-new-kind-of-sigdev_025.png"} forKey:@"Woman"];
    [augmentationDict setValue:@{
                             @"shader": @"Simple",
                             @"texture": @"Intercept-the-art-of-deception-training-for-a-new_034.png"} forKey:@"Buffalo"];
    [augmentationDict setValue:@{
                             @"shader": @"DistortedTV",
                             @"texture": @"Intercept-the-art-of-deception-training-for-a-new_021.png"} forKey:@"Bosch"];
    [augmentationDict setValue:@{
                            @"shader": @"DistortedTV",
                            @"texture": @"",
                            @"video":@"1984Macintosh.m4v"} forKey:@"1984"];
    [augmentationDict setValue:@{
                            @"shader": @"Simple",
                            @"texture": @"",
                            @"video":@"HackersSceneForAFS.m4v"} forKey:@"CyberMagicians"];
    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"DerSpiegel-image-542019-galleryV9-hheg.png"} forKey:@"Afghan"];
    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"card_texture.png"} forKey:@"Cards"];
    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"curvedDisplayTexture.png"} forKey:@"Buffalo"];

    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"Intercept-the-art-of-deception-training-for-a-new_025.png"} forKey:@"Women"];
    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"ask_zelda.png"} forKey:@"Zelda"];

    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"Intercept-the-art-of-deception-training-for-a-new_035.png"} forKey:@"UFO"];
    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"textureArray": @[
                                     @"phantasmagoria001.png",
                                     @"phantasmagoria002.png"]} forKey:@"Kidnapper"];

    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"",
                                 @"video":@"YoussefForAFS.m4v"} forKey:@"Egypt"];
    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"",
                                 @"video":@"OliverFerguson.m4v"} forKey:@"Tank"];
    
    [augmentationDict setValue:@{
                                 @"shader": @"ChromaKey",
                                 @"texture": @"",
                                 @"video":@"Intercept-psychology-a-new-kind-of-sigdev_007.m4v"} forKey:@"CatDog"];
    /*
    [augmentationDict setValue:@{
                                 @"shader": @"ChromaKey",
                                 @"texture": @"Intercept-psychology-a-new-kind-of-sigdev_007.png"} forKey:@"CatDog"];
     */
    [augmentationDict setValue:@{
                                 @"shader": @"Animate_8x8",
                                 @"texture": @"Intercept-psychology-a-new-kind-of-sigdev_024_spriteSheet.png"} forKey:@"Couple"];
    [augmentationDict setValue:@{
                                 @"shader": @"Animate_4x5",
                                 @"texture": @"DerSpiegel-nsa-quantumtheory_002_sprites.png"} forKey:@"Foxacid"];
    [augmentationDict setValue:@{
                                 @"shader": @"Simple",
                                 @"texture": @"Intercept-the-art-of-deception-training-for-a-new_022.png"} forKey:@"RabbitDuck"];
    
    /* 
     * AUGMENTATIONS TO AUGMENT
     * :-) (i.e., make better) 
     */
    

    
    /* 
     * AUGMENTATIONS THAT ARE NOT DONE YET
     */
    [augmentationDict setValue:@{
                            @"shader": @"Simple",
                            @"texture": @"WashingtonPost-fisa03201404590770.png"} forKey:@"BlurredFaces"];
    
    /*
     * DEFAULT AUGMENTATION
     * Change when we are done with all of the augmentations
     */
    [augmentationDict setValue:@{
                            @"shader": @"Simple",
                            @"texture": @"transparent.png"} forKey:@"default"];
}

- (void)loadTextureIDs {
    for (NSString *key in augmentationDict) {
        NSDictionary *dict = [augmentationDict objectForKey:key];
        NSString *textureFilename = [dict valueForKey:@"texture"];
        
        if (textureFilename == nil) {
            // Try the key "textureArray"
            NSArray *textureArray = [dict valueForKey:@"textureArray"];
            
            for (NSString *arrayItem in textureArray) {
                if ([arrayItem isEqualToString:@""]) {
                    continue;
                } else {
                    [self loadTextureWith:arrayItem];
                }
            }
            
        } else {
            // If no texture is set for this particular trackable, skip
            if ([textureFilename isEqualToString:@""]) {
                continue;
            }
            
            // Otherwise, load the texture
            [self loadTextureWith:textureFilename];
        }
        
    }
}

- (void)loadTextureWith:(NSString *)textureFilename {
    Texture* t = [[Texture alloc] initWithImageFile:textureFilename];
    
    GLuint textureID;
    glGenTextures(1, &textureID);
    [t setTextureID:textureID];
    glBindTexture(GL_TEXTURE_2D, textureID);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    //glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, [t width], [t height], 0, GL_RGBA, GL_UNSIGNED_BYTE, (GLvoid*)[t pngData]);
    glBindTexture(GL_TEXTURE_2D, 0);
    //NSLog(@"Loaded texture '%@' with textureID %d", textureFilename, textureID);
    [textureIDs setObject:t forKey:textureFilename];
    
}

// From RosyWriter
- (UILabel *)labelWithText:(NSString *)text yPosition:(CGFloat)yPosition
{
	//CGFloat labelWidth = 200.0;
	//CGFloat labelHeight = 400.0;
    // TODO: Deal better with content scaling/retina displays than this hardcoded sample.
    // TODO: Need to deal with proper positioning, padding
    CGFloat labelHeight = self.bounds.size.height/2.0;
    CGFloat labelWidth = self.bounds.size.width/2.0;
	//CGFloat xPosition = self.bounds.size.width - labelWidth - 10;
	//CGRect labelFrame = CGRectMake(xPosition, yPosition, labelWidth, labelHeight);
    CGRect labelFrame = CGRectMake(0, 0, labelWidth, labelHeight);
	UILabel *label = [[UILabel alloc] initWithFrame:labelFrame];
	[label setFont:[UIFont systemFontOfSize:36]];
    // TODO: Figure out how to set the following parameters in ios 7
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
    
    if (state.getNumTrackableResults() == 0) {
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"NoTargetsNotification" object:nil userInfo:nil];
        });
    }
    
    for (int i = 0; i < state.getNumTrackableResults(); ++i) {
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"TargetsNotification" object:nil userInfo:nil];
        });
        
        // Get the trackable
        const QCAR::TrackableResult* result = state.getTrackableResult(i);
        const QCAR::Trackable& trackable = result->getTrackable();
        QCAR::Matrix44F modelViewMatrix = QCAR::Tool::convertPose2GLMatrix(result->getPose());
        trackableName = [NSMutableString stringWithUTF8String:trackable.getName()];
        
        // Check if we have anything for this trackable in our dict
        if ([augmentationDict valueForKey:trackableName] == nil) {
            trackableName = @"default";
        }
        
        [self setCurrentTrackableWith:trackableName];
        
        // Here, we branch to different types of augmentations
        // Some are simple and just are texture replacements using different shader programs
        // Others do video playback or loading of models and particle systems
        
        if ([currentTrackable isEqualToString:@"Foxacid"]) {
            [self animateFoxacid:[augmentationDict objectForKey:@"Foxacid"] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        } else if ([currentTrackable isEqualToString:@"Couple"]) {
            [self animateDolphin:[augmentationDict objectForKey:@"Couple"] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        } else if ([currentTrackable isEqualToString:@"Kidnapper"]) {
            [self animatePhantasmagoria:[augmentationDict objectForKey:@"Kidnapper"] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        } else if ([currentTrackable isEqualToString:@"BlurredFaces"]) {
            // This isn't working right now, so we skip it
            [self augmentBlurredFaces:[augmentationDict objectForKey:@"BlurredFaces"] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
            
            //[self applyTextureWithTextureFile:[augmentationDict objectForKey:currentTrackable] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        } else if ([currentTrackable isEqualToString:@"CyberMagicians"]) {
            [self playVideoWithTrackable:trackable withCurrentResult:result];
        } else if ([currentTrackable isEqualToString:@"Egypt"]) {
            [self playVideoWithTrackable:trackable withCurrentResult:result];
        } else if ([currentTrackable isEqualToString:@"Tank"]) {
            [self playVideoWithTrackable:trackable withCurrentResult:result];
        } else if ([currentTrackable isEqualToString:@"CatDog"]) {
            [self playVideoWithTrackable:trackable withCurrentResult:result];
        } else if ([currentTrackable isEqualToString:@"1984"]) {
            [self playVideoWithTrackable:trackable withCurrentResult:result];
        } else if ([currentTrackable isEqualToString:@"Cards"]) {
            [self augmentCards:[augmentationDict objectForKey:@"Cards"] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        } else if ([currentTrackable isEqualToString:@"Buffalo"]) {
            [self augmentBuffalo:[augmentationDict objectForKey:@"Buffalo"] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
        } else {
            // Do our generic apply texture with the selected shader program, set in setCurrentTrackableWith:trackableName
            [self applyTextureWithTextureFile:[augmentationDict objectForKey:currentTrackable] modelViewMatrix:modelViewMatrix shaderProgramID:shaderProgramID];
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

//------------------------------------------------------------------------------
#pragma mark - Augmentation methods

- (void)applyTextureWithTextureFile:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    // OpenGL 2
    QCAR::Matrix44F modelViewProjection;
    
    if ([currentTrackable isEqualToString:@"RabbitDuck"]) {
        SampleApplicationUtils::translatePoseMatrix(rdXPos, rdYPos, 0.0f, &modelViewMatrix.data[0]);
        SampleApplicationUtils::translatePoseMatrix(-30.0, 0.0f, 0.0f, &modelViewMatrix.data[0]);
    } else if ([currentTrackable isEqualToString:@"BlurredFaces"]) {
        SampleApplicationUtils::translatePoseMatrix(0.0, -1.0f, 0.0f, &modelViewMatrix.data[0]);
    } else {
        SampleApplicationUtils::translatePoseMatrix(0.0f, -1.0f, 0.0f, &modelViewMatrix.data[0]);
    }
    
    //SampleApplicationUtils::translatePoseMatrix(0, 0, 30.0, &modelViewMatrix.data[0]);
    //SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0, &modelViewMatrix.data[0]);
    if ([currentTrackable isEqualToString:@"Women"]) {
        SampleApplicationUtils::scalePoseMatrix(0.95*kObjectScaleNormalx, kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
    } else if ([currentTrackable isEqualToString:@"Anchory"]) {
        SampleApplicationUtils::scalePoseMatrix(0.95*kObjectScaleNormalx, 0.95*kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
    } else if ([currentTrackable isEqualToString:@"BlurredFaces"]) {
        SampleApplicationUtils::scalePoseMatrix(0.97*kObjectScaleNormalx, 0.48*kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
    } else {
        SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormalx, kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
    }
    
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
    
    glDepthFunc(GL_LEQUAL);
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
    
    SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
}

- (void)augmentCards:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    // OpenGL 2
    
    
    float xPos;
    float yPos;
    float zPos;
    float xRot;
    float yRot;
    float zRot;
    float rotAngle;
    //xPos = -100.0;
    
    
    //QCAR::Matrix44F originalMVMatrix = modelViewMatrix;
    float originalMVMatrixData[16];
    
    for (int i = 0; i < NUM_CARDS; i++) {
        QCAR::Matrix44F modelViewProjection;
        memcpy(originalMVMatrixData, modelViewMatrix.data, sizeof(modelViewMatrix.data));
        AFSCardParticle *currentCard;
        currentCard = [[emitter cardEmitter] objectAtIndex:i];
        
        xPos = currentCard.xPos;
        yPos = currentCard.yPos;
        zPos = currentCard.zPos;
        
        xRot = currentCard.xRot;
        yRot = currentCard.yRot;
        zRot = currentCard.zRot;
        
        rotAngle = currentCard.angle;
        
        // Set the position of the card
        //SampleApplicationUtils::translatePoseMatrix(xPos, -1.0f, zPos, &originalMVMatrixData[0]);
        SampleApplicationUtils::translatePoseMatrix(xPos, yPos, zPos, &originalMVMatrixData[0]);
        
        // Scale to a normal size
        SampleApplicationUtils::scalePoseMatrix(kCardsScaleNormal, kCardsScaleNormal, kCardsScaleNormal, &originalMVMatrixData[0]);
        
        // Rotate accordingly
        // First, rotate to that we default to facing the viewer
        SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0, &originalMVMatrixData[0]);
        // Then, rotate away!
        SampleApplicationUtils::rotatePoseMatrix(rotAngle, xRot, yRot, zRot, &originalMVMatrixData[0]);
        
        SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &originalMVMatrixData[0], &modelViewProjection.data[0]);
        
        glUseProgram(shaderID);
        
        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)cardVerts);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)cardNormals);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)cardTexCoords);
        
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
        glDrawArrays(GL_TRIANGLES, 0, cardNumVerts);
        //xPos += 30.0;
    }
    [emitter updateLifeCycle];
    
    SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
}

- (void)augmentBuffalo:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    // OpenGL 2
    
    
    
    //QCAR::Matrix44F originalMVMatrix = modelViewMatrix;
    float originalMVMatrixData[16];
    
    QCAR::Matrix44F modelViewProjection;
    memcpy(originalMVMatrixData, modelViewMatrix.data, sizeof(modelViewMatrix.data));
    
    // Set the position
    SampleApplicationUtils::translatePoseMatrix(0.0, 300.0f, 1.0, &originalMVMatrixData[0]);
    
    
    // Scale to a normal size
    SampleApplicationUtils::scalePoseMatrix(10*kObjectScaleNormal, 10*kObjectScaleNormal, 10*kObjectScaleNormal, &originalMVMatrixData[0]);
    
    // Rotate accordingly
    // First, rotate to that we default to facing the viewer
    //SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0, &originalMVMatrixData[0]);
    SampleApplicationUtils::rotatePoseMatrix(90, 1, 0, 0, &originalMVMatrixData[0]);
    SampleApplicationUtils::rotatePoseMatrix(-90, 0, 1, 0, &originalMVMatrixData[0]);
    
    // Then, rotate away!
    //SampleApplicationUtils::rotatePoseMatrix(rotAngle, xRot, yRot, zRot, &originalMVMatrixData[0]);
    
    SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &originalMVMatrixData[0], &modelViewProjection.data[0]);
    
    glUseProgram(shaderID);
    
    glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)curvedDisplayVerts);
    glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)curvedDisplayNormals);
    glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)curvedDisplayTexCoords);
    
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
    glDrawArrays(GL_TRIANGLES, 0, curvedDisplayNumVerts);
    //xPos += 30.0;
    
    SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
}

- (void) playVideoWithTrackable:(const QCAR::Trackable& )trackable withCurrentResult:(const QCAR::TrackableResult*) result  {
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
    // Set the frameTextureID to the default texture to avoid any potential problems with unset values
    GLuint frameTextureID = 0;
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
        // NOTE
        // Placing the video drawing code here to prevent having to create a keyframe
        
        // ---- Display the video frame -----
        aspectRatio = (float)[videoPlayerHelper getVideoHeight] / (float)[videoPlayerHelper getVideoWidth];
        texCoords = videoQuadTextureCoords;
        
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
            
            // This is the trick to enable chroma keying
            // Set glBlendFunc to be GL_SRC_ALPHA, and then reset to GL_ONE after drawing
            glDepthFunc(GL_LEQUAL);
            glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_BLEND);
            
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, quadIndices);
            
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_BLEND);
            
            glDisableVertexAttribArray(vertexHandle);
            glDisableVertexAttribArray(normalHandle);
            glDisableVertexAttribArray(textureCoordHandle);
            
            glUseProgram(0);
        }
        
    }
    else {
        // Don't display anything if we're not ready
        
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
    SampleApplicationUtils::translatePoseMatrix(-0.37, 0.09, 0.0f, &modelViewMatrix.data[0]);
    SampleApplicationUtils::scalePoseMatrix(0.55, 0.71, 1, &modelViewMatrix.data[0]);
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

- (void)animateDolphin:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    // OpenGL 2
    QCAR::Matrix44F modelViewProjection;
    
    SampleApplicationUtils::translatePoseMatrix(0.0f, -1.0f, 0.0f, &modelViewMatrix.data[0]);
    SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormalx, kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
    
    
    // If sprite sheet is organized from right to left, then we need to offset by the last x position
    float currentRowPosition = 0.875 - (((dolphin_currentFrame) % dolphin_FramesPerRow) * 1.0f / dolphin_FramesPerRow);
    //NSLog(@"Current row position: %f", currentRowPosition);
    float currentColumnPosition = ((dolphin_currentFrame) / dolphin_FramesPerRow) * 1.0f / dolphin_FramesPerColumn;
    //NSLog(@"Current column position: %f", currentColumnPosition);
    //SampleApplicationUtils::translatePoseMatrix(currentRowPosition, currentColumnPosition, 0.0f, &modelViewMatrix.data[0]);
    //SampleApplicationUtils::scalePoseMatrix(1.0f/dolphin_FramesPerRow, 1/dolphin_FramesPerColumn, 1, &modelViewMatrix.data[0]);
    SampleApplicationUtils::translatePoseMatrix(-0.15f, -0.10f, 0.0f, &modelViewMatrix.data[0]);
    SampleApplicationUtils::scalePoseMatrix(0.64f, 1.0f, 1, &modelViewMatrix.data[0]);
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
    //glUniform1f(frameHandle, dolphin_currentFrame);
    //glUniform1f(frameRowHandle, currentRowPosition);
    //glUniform1f(frameColumnHandle, currentColumnPosition);
    glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
    [self updateDolphinParams];
    glUniform1f(timeHandle, time);
    glUniform2fv(resolutionHandle, 1, resolution);
    
    glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
    glEnable(GL_BLEND);
    glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
    
    SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
}

- (void)animatePhantasmagoria:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    float originalMVMatrixData[16];
    float zPos = 0.05;
    
    for (int i = 0; i < NUM_PHANTASMAGORIA_TEXTURES; i++) {
        QCAR::Matrix44F modelViewProjection;
        memcpy(originalMVMatrixData, modelViewMatrix.data, sizeof(modelViewMatrix.data));
        
        SampleApplicationUtils::translatePoseMatrix(0.0f, -1.0f, 0.0f, &originalMVMatrixData[0]);
        SampleApplicationUtils::scalePoseMatrix(phScale[i][0]*kObjectScaleNormalx, phScale[i][1]*kObjectScaleNormaly, 1, &originalMVMatrixData[0]);
        
        // TODO: Render each image to an FBO, recombine and mix in a shader, so as to eliminate need for translating
        // to different z positions
        SampleApplicationUtils::translatePoseMatrix(phCurrentPos[i][0], phCurrentPos[i][1], i * zPos, &originalMVMatrixData[0]);
        //NSLog(@"%d: x: %f, y: %f", i, phCurrentPos[i][0], phCurrentPos[i][1]);
        
        //SampleApplicationUtils::translatePoseMatrix(-0.15f, -0.10f, 0.0f, &modelViewMatrix.data[0]);
        //SampleApplicationUtils::scalePoseMatrix(phScale[i][1], phScale[i][1], 1, &modelViewMatrix.data[0]);
        SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &originalMVMatrixData[0], &modelViewProjection.data[0]);
        
        glUseProgram(shaderID);
        
        glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadVertices);
        glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadNormals);
        glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadTexCoords);
        
        glEnableVertexAttribArray(vertexHandle);
        glEnableVertexAttribArray(normalHandle);
        glEnableVertexAttribArray(textureCoordHandle);
        
        glActiveTexture(GL_TEXTURE0);
        
        //NSString *textureFile = [textureInfo objectForKey:@"texture"];
        Texture* currentTexture = (Texture *)[textureIDs objectForKey:phTextures[i]];
        glBindTexture(GL_TEXTURE_2D, currentTexture.textureID);
        
        glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
        glUniform1i(texSampler2DHandle, 0 /*GL_TEXTURE0*/);
        [self updatePhantasmagoriaParams];
        
        glUniform1f(timeHandle, time);
        glUniform2fv(resolutionHandle, 1, resolution);
        
        glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
        glEnable(GL_BLEND);
        glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
    }
    
    SampleApplicationUtils::checkGlError("EAGLView renderFrameQCAR");
}


- (void)augmentBlurredFaces:(NSDictionary *)textureInfo modelViewMatrix:(QCAR::Matrix44F)modelViewMatrix shaderProgramID:(GLuint)shaderID {
    // OpenGL 2
    [self updateBlurredFacesParams];
    
    switch (blurredFaces_state) {
        case PRE_CAPTURE_FACE: {
            // Stop Tracker
            //[afsImageTargetsViewController doUnloadTrackersData];
            //[afsImageTargetsViewController doStopTrackers];
            //[afsImageTargetsViewController doDeinitTrackers];
            
            // Stop camera
            //QCAR::CameraDevice::getInstance().stop();
            //QCAR::CameraDevice::getInstance().deinit();
            
            blurredFaces_state = SETUP_CAPTURE_FACE;
            NSLog(@"Switching to SETUP_CAPTURE_FACE");
            break;
        }
        case SETUP_CAPTURE_FACE: {
            self.cicontext = [CIContext contextWithEAGLContext:context];
            self.currentFrontImage = [CIImage emptyImage];
            
            NSError *error = nil;
            session = [[AVCaptureSession alloc] init];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone){
                [session setSessionPreset:AVCaptureSessionPreset640x480];
            } else {
                [session setSessionPreset:AVCaptureSessionPresetPhoto];
            }
            // Select a video device, make an input
            AVCaptureDevice *device = nil;
            AVCaptureDevicePosition desiredPosition = AVCaptureDevicePositionFront;
            // find the front facing camera
            for (AVCaptureDevice *d in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
                if ([d position] == desiredPosition) {
                    device = d;
                    self.isUsingFrontFacingCamera = YES;
                    break;
                }
            }
            // fall back to the default camera.
            if( nil == device )
            {
                self.isUsingFrontFacingCamera = NO;
                device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
            }
            // get the input device
            AVCaptureDeviceInput *deviceInput = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
            if( !error ) {
                
                // add the input to the session
                if ( [session canAddInput:deviceInput] ){
                    [session addInput:deviceInput];
                }
                
                // Make a video data output
                self.videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
                
                // we want BGRA, both CoreGraphics and OpenGL work well with 'BGRA'
                NSDictionary *rgbOutputSettings = [NSDictionary dictionaryWithObject:
                                                   [NSNumber numberWithInt:kCMPixelFormat_32BGRA] forKey:(id)kCVPixelBufferPixelFormatTypeKey];
                [self.videoDataOutput setVideoSettings:rgbOutputSettings];
                [self.videoDataOutput setAlwaysDiscardsLateVideoFrames:YES]; // discard if the data output queue is blocked
                
                // create a serial dispatch queue used for the sample buffer delegate
                // a serial dispatch queue must be used to guarantee that video frames will be delivered in order
                // see the header doc for setSampleBufferDelegate:queue: for more information
                self.videoDataOutputQueue = dispatch_queue_create("VideoDataOutputQueue", DISPATCH_QUEUE_SERIAL);
                [self.videoDataOutput setSampleBufferDelegate:self queue:self.videoDataOutputQueue];
                
                if ( [session canAddOutput:self.videoDataOutput] ){
                    [session addOutput:self.videoDataOutput];
                }
                
                // get the output for doing face detection.
                [[self.videoDataOutput connectionWithMediaType:AVMediaTypeVideo] setEnabled:YES];
                
                // TODO: somewhat brittle, assuming we have only one connection here
                AVCaptureConnection *conn = [self.videoDataOutput connections][0];
                
                // See here: https://developer.apple.com/library/ios/qa/qa1744/_index.html
                UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
                if ([conn isVideoOrientationSupported])
                {
                    if (curDeviceOrientation == UIDeviceOrientationPortrait) {
                        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
                        [conn setVideoOrientation:orientation];
                    } else if (curDeviceOrientation == UIDeviceOrientationLandscapeLeft) {
                        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;
                        [conn setVideoOrientation:orientation];
                    } else if (curDeviceOrientation == UIDeviceOrientationLandscapeRight) {
                        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
                        [conn setVideoOrientation:orientation];
                    } else if (curDeviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
                        AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortraitUpsideDown;
                        [conn setVideoOrientation:orientation];
                    }
                    
                }
                
                self.videoPreviewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
                self.videoPreviewLayer.backgroundColor = [[UIColor blackColor] CGColor];
                self.videoPreviewLayer.videoGravity = AVLayerVideoGravityResizeAspect;
                
                CALayer *rootLayer = [self.videoPreviewLayer presentationLayer];
                [rootLayer setMasksToBounds:YES];
                [self.videoPreviewLayer setFrame:[rootLayer bounds]];
                [rootLayer addSublayer:self.videoPreviewLayer];
                [session startRunning];
            }
            
            session = nil;
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:
                                          [NSString stringWithFormat:@"Failed with error %d", (int)[error code]]
                                                                    message:[error localizedDescription]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"Dismiss"
                                                          otherButtonTitles:nil];
                [alertView show];
                [self teardownAVCapture];
            }
            
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glFlush();
            
            // Setup our shader for the next stage of processing
            [self selectShaderWithName:@"PassthroughWAlpha"];
            
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"CaptureFaceNotification" object:nil userInfo:nil];
            });
            
            blurredFaces_state = CAPTURE_FACE;
            NSLog(@"Switching to CAPTURE_FACE");
            break;
        }
        case CAPTURE_FACE: {
            // Post our notifications
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"NoTargetsNotification" object:nil userInfo:nil];
            });
            
            // Rotate our image to work on landscape
            // TODO: Perhaps, at some point, deal with other orientations
            CGRect newRect = CGRectMake(0, 0, self.eaglFrame.size.height, self.eaglFrame.size.width);
            CIImage *rotatedImage = [self.currentFrontImage imageByApplyingTransform:CGAffineTransformMakeRotation(M_PI)];
            
            // Mirror the image in X
            rotatedImage = [rotatedImage imageByApplyingTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), 0, rotatedImage.extent.size.width)];
            
            NSMutableDictionary *imageOptions = nil;
            
            // Setup our face detector
            imageOptions = [NSMutableDictionary dictionaryWithObject:[self exifOrientation:[[UIDevice currentDevice] orientation]] forKey:CIDetectorImageOrientation];
            //[imageOptions setObject:[NSNumber numberWithInt:6] forKey:CIDetectorImageOrientation];
            
            NSArray *features = [self.faceDetector featuresInImage:self.currentFrontImage
                                                           options:imageOptions];
            
            // Check for features and save rects and points
            for (CIFaceFeature *faceFeature in features) {
                self.faceRect = [faceFeature bounds];
                
                if ([faceFeature hasLeftEyePosition]) {
                    CGPoint temp = [faceFeature leftEyePosition];
                    self.leftEyePoint = CGPointMake(fabsf(temp.x), fabsf(temp.y));
                } else {
                    self.leftEyePoint = CGPointMake(0.0, 0.0);
                }
                
                if ([faceFeature hasRightEyePosition]) {
                    CGPoint temp = [faceFeature rightEyePosition];
                    self.rightEyePoint = CGPointMake(fabsf(temp.x), fabsf(temp.y));
                } else {
                    self.rightEyePoint = CGPointMake(0.0, 0.0);
                }
            }
            
//
//            NSLog(@"in CAPTURE_FACE, rotatedImage width: %f", rotatedImage.extent.size.width);
//            NSLog(@"in CAPTURE_FACE, rotatedImage height: %f", rotatedImage.extent.size.height);
//            NSLog(@"in CAPTURE_FACE, leftEyePoint: %@", NSStringFromCGPoint(self.leftEyePoint));
//            NSLog(@"in CAPTURE_FACE, rightEyePoint: %@", NSStringFromCGPoint(self.rightEyePoint));
            
            // Actually draw our image in the EAGL view
            [self.cicontext drawImage:rotatedImage
                               inRect:newRect
                             fromRect:rotatedImage.extent];
            
            // Now let's draw a box that blocks out the eyes
            glUseProgram(shaderID);
            
            // After scaling and flipping the coordinate system, we can think of our quad and offset points in a normal coordinate system with origin LL.
            // Not sure why I have to add to much to the LR and UR x offset, but it works; maybe the eye tracking is off somehow?
            CGSize extent = rotatedImage.extent.size;
            CGPoint LL = [self scalePoint:CGPointMake(self.leftEyePoint.x, self.leftEyePoint.y) withExtent:extent andOffset:CGPointMake(-10, -40)];
            CGPoint LR = [self scalePoint:CGPointMake(self.rightEyePoint.x, self.rightEyePoint.y) withExtent:extent andOffset:CGPointMake(120, -40)];
            CGPoint UR = [self scalePoint:CGPointMake(self.rightEyePoint.x, self.rightEyePoint.y) withExtent:extent andOffset:CGPointMake(120, 40)];
            CGPoint UL = [self scalePoint:CGPointMake(self.leftEyePoint.x, self.leftEyePoint.y) withExtent:extent andOffset:CGPointMake(-10, 40)];
            
            /*
            NSLog(@"LL: %@", NSStringFromCGPoint(LL));
            NSLog(@"LR: %@", NSStringFromCGPoint(LR));
            NSLog(@"UR: %@", NSStringFromCGPoint(UR));
            NSLog(@"UL: %@", NSStringFromCGPoint(UL));
             */
            
            // Mirror in the x coordinate so that the image and box appear as expected
            float newQuadVertices[4*3] = {
                -1.0f*LR.x,  LR.y,  0.0f,
                -1.0f*LL.x,  LL.y,  0.0f,
                -1.0f*UL.x,   UL.y,  0.0f,
                -1.0f*UR.x,   UR.y,  0.0f,
            };

            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)newQuadVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadTexCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            
            glUniform1f(timeHandle, time);
            glUniform1f(alphaHandle, alpha);
            glUniform2fv(resolutionHandle, 1, resolution);
            
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_BLEND);
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
            
            SampleApplicationUtils::checkGlError("CAPTURE_FACE EAGLView renderFrameQCAR");
            break;
        }
        case PRE_AUGMENT_FACE: {
            // Start things up again
            dispatch_async(dispatch_get_main_queue(),^{
                [[NSNotificationCenter defaultCenter] postNotificationName:@"PreAugmentFaceNotification" object:nil userInfo:nil];
            });
            
            // Restart the camera
            QCAR::CameraDevice::getInstance().stop();
            QCAR::CameraDevice::getInstance().start();
            QCAR::CameraDevice::getInstance().setFocusMode(QCAR::CameraDevice::FOCUS_MODE_CONTINUOUSAUTO);
            
            // Render rect of face to the FBO
            // Clear everything before we begin drawing to our FBO
            glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
            glFlush();
            
            glActiveTexture(GL_TEXTURE0);
            glBindTexture(GL_TEXTURE_2D, 0);

            glBindFramebuffer(GL_FRAMEBUFFER, facesFBOHandle);
            
            glViewport(0, 0, facesFBOWidth, facesFBOHeight);
            
            // Create a rect the size of our image
            CGRect inRect = CGRectMake(0, 0, facesFBOWidth, facesFBOHeight);
            //NSLog(@"EXTENT: %@", NSStringFromCGRect(self.currentFrontImage.extent));
            //NSLog(@"FACE RECT: %@", NSStringFromCGRect(self.faceRect));
            
            // Run our own face detector here at high accuracy
            CIDetector* detector = [CIDetector detectorOfType:CIDetectorTypeFace
                                                      context:nil
                                                      options:[NSDictionary dictionaryWithObject:CIDetectorAccuracyHigh forKey:CIDetectorAccuracy]];
            
            // Assume that we're working in landscape right, for now
            CIImage *rotatedImage = [self.currentFrontImage imageByApplyingTransform:CGAffineTransformMakeRotation(M_PI)];
            // Mirror the image in X
            rotatedImage = [rotatedImage imageByApplyingTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), 0, rotatedImage.extent.size.width)];
            
            // Go through our features
            NSArray* features = [detector featuresInImage:rotatedImage];
            for(CIFaceFeature* faceFeature in features) {
                self.faceRect = [faceFeature bounds];
                
                if ([faceFeature hasLeftEyePosition]) {
                    CGPoint temp = [faceFeature leftEyePosition];
                    self.leftEyePoint = CGPointMake(fabsf(temp.x), fabsf(temp.y));
                } else {
                    self.leftEyePoint = CGPointMake(0.0, 0.0);
                }
                
                if ([faceFeature hasRightEyePosition]) {
                    CGPoint temp = [faceFeature rightEyePosition];
                    self.rightEyePoint = CGPointMake(fabsf(temp.x), fabsf(temp.y));
                } else {
                    self.rightEyePoint = CGPointMake(0.0, 0.0);
                }
                
            }
            
            
//            NSLog(@"EXTENT (rotated): %@", NSStringFromCGRect(rotatedImage.extent));
//            NSLog(@"faceRect in PRE_AUGMENT_FACES: %@", NSStringFromCGRect(self.faceRect));
//            NSLog(@"leftEyePoint in PRE_AUGMENT_FACES: %@", NSStringFromCGPoint(self.leftEyePoint));
//            NSLog(@"rightEyePoint in PRE_AUGMENT_FACES: %@", NSStringFromCGPoint(self.rightEyePoint));
            
            // Gaussian blur the image
            CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
            [filter setValue:rotatedImage forKey:kCIInputImageKey];
            [filter setValue:[NSNumber numberWithFloat:10.0f] forKey:@"inputRadius"];
            CIImage *result = [filter valueForKey:kCIOutputImageKey];
            
            [self.cicontext drawImage:result
                               inRect:inRect
                             fromRect:CGRectIntersection(rotatedImage.extent, self.faceRect)];
            
            glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);
            
            // Define our box coordinates in GL space
            CGSize extent = self.faceRect.size;
            float xOffset = fabsf(self.faceRect.origin.x);
            //float scaleFactorX = fabsf(self.faceRect.size.width/rotatedImage.extent.size.width);
            float yOffset = fabsf(self.faceRect.origin.y);
            //float scaleFactorY = fabsf(self.faceRect.size.height/rotatedImage.extent.size.height);

            //NSLog(@"EXTENT IN PRE_AUGMENT_FACES: %@", NSStringFromCGSize(extent));

            // TODO: This transformation could probably be made better and more accurate
            CGPoint LL = [self noResetScalePoint:CGPointMake((self.leftEyePoint.x - xOffset), (self.leftEyePoint.y - yOffset)) withExtent:extent andOffset:CGPointMake(-80, -50)];
            CGPoint LR = [self noResetScalePoint:CGPointMake((self.rightEyePoint.x - xOffset), (self.rightEyePoint.y - yOffset)) withExtent:extent andOffset:CGPointMake(160, -50)];
            CGPoint UR = [self noResetScalePoint:CGPointMake((self.rightEyePoint.x - xOffset), (self.rightEyePoint.y - yOffset)) withExtent:extent andOffset:CGPointMake(160, 50)];
            CGPoint UL = [self noResetScalePoint:CGPointMake((self.leftEyePoint.x - xOffset), (self.leftEyePoint.y - yOffset)) withExtent:extent andOffset:CGPointMake(-80, 50)];
            
//            NSLog(@"LL: %@", NSStringFromCGPoint(LL));
//            NSLog(@"LR: %@", NSStringFromCGPoint(LR));
//            NSLog(@"UR: %@", NSStringFromCGPoint(UR));
//            NSLog(@"UL: %@", NSStringFromCGPoint(UL));
            
            // LL vertex
            eyeBoxQuadVertices[0] = LL.x;
            eyeBoxQuadVertices[1] = LL.y;
            // LR vertex
            eyeBoxQuadVertices[3] = LR.x;
            eyeBoxQuadVertices[4] = LR.y;
            // UR vertex
            eyeBoxQuadVertices[6] = UR.x;
            eyeBoxQuadVertices[7] = UR.y;
            // UL vertex
            eyeBoxQuadVertices[9] = UL.x;
            eyeBoxQuadVertices[10] = UL.y;
            
            /*
            // Faking it
            // LL vertex
            eyeBoxQuadVertices[0] = -0.75;
            eyeBoxQuadVertices[1] = 0.3;
            // LR vertex
            eyeBoxQuadVertices[3] = 0.75;
            eyeBoxQuadVertices[4] = 0.3;
            // UR vertex
            eyeBoxQuadVertices[6] = 0.75;
            eyeBoxQuadVertices[7] = 0.7;
            // UL vertex
            eyeBoxQuadVertices[9] = -0.75;
            eyeBoxQuadVertices[10] = 0.7;
            */
            
            blurredFaces_state = AUGMENT_FACE;
            NSLog(@"Switching to AUGMENT_FACE");
            
            SampleApplicationUtils::checkGlError("PRE_AUGMENT_FACE EAGLView renderFrameQCAR");
            break;
        }
        case AUGMENT_FACE: {
            QCAR::Matrix44F modelViewProjection;
            
            float MVMatrixDataCopy[16];
            memcpy(MVMatrixDataCopy, modelViewMatrix.data, sizeof(modelViewMatrix.data));
            
            SampleApplicationUtils::translatePoseMatrix(50.0f, -3.0f, 0.2f, &modelViewMatrix.data[0]);
            //SampleApplicationUtils::translatePoseMatrix(0.0, 0.0f, 0.2f, &modelViewMatrix.data[0]);
            SampleApplicationUtils::scalePoseMatrix(0.3*kObjectScaleNormalx, 0.35*kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
            //SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormalx, kObjectScaleNormaly, 1, &modelViewMatrix.data[0]);
            
            SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &modelViewMatrix.data[0], &modelViewProjection.data[0]);
            
            
            [self selectShaderWithName:@"SimpleNoTexture"];
            glUseProgram(shaderID);
            
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)eyeBoxQuadVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadTexCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            
            glUniform1f(timeHandle, time);
            glUniform2fv(resolutionHandle, 1, resolution);
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
            
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_BLEND);
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
            
            
            // Draw face
            SampleApplicationUtils::translatePoseMatrix(50.0f, -3.0f, 0.0f, &MVMatrixDataCopy[0]);
            //SampleApplicationUtils::translatePoseMatrix(0.0, 0.0f, 0.0f, &MVMatrixDataCopy[0]);
            SampleApplicationUtils::scalePoseMatrix(0.3*kObjectScaleNormalx, 0.35*kObjectScaleNormaly, 1, &MVMatrixDataCopy[0]);
            //SampleApplicationUtils::scalePoseMatrix(kObjectScaleNormalx, kObjectScaleNormaly, 1, &MVMatrixDataCopy[0]);
            
            SampleApplicationUtils::multiplyMatrix(&vapp.projectionMatrix.data[0], &MVMatrixDataCopy[0], &modelViewProjection.data[0]);
            [self selectShaderWithName:@"Simple"];
            glUseProgram(shaderID);
            
            glVertexAttribPointer(vertexHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadVertices);
            glVertexAttribPointer(normalHandle, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadNormals);
            glVertexAttribPointer(textureCoordHandle, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid*)quadTexCoords);
            
            glEnableVertexAttribArray(vertexHandle);
            glEnableVertexAttribArray(normalHandle);
            glEnableVertexAttribArray(textureCoordHandle);
            
            glActiveTexture(GL_TEXTURE0);
            
            // Try binding the FBO texture
            glBindTexture(GL_TEXTURE_2D, facesFBOTexture);
            
            glUniformMatrix4fv(mvpMatrixHandle, 1, GL_FALSE, (const GLfloat*)&modelViewProjection.data[0]);
            glUniform1i(texSampler2DHandle, 0);
            
            glUniform1f(timeHandle, time);
            glUniform2fv(resolutionHandle, 1, resolution);
            
            glBlendFunc(GL_ONE, GL_ONE_MINUS_SRC_ALPHA);
            glEnable(GL_BLEND);
            glDrawElements(GL_TRIANGLES, NUM_QUAD_INDEX, GL_UNSIGNED_SHORT, (const GLvoid*)quadIndices);
            
            // TODO: We get a 0x502 glError, and I think it's due to the mvpMatrixHandle line, but not sure why it's occuring...
            // Ignoring for now, as it doesn't seem to harm the app
            SampleApplicationUtils::checkGlError("AUGMENT_FACE EAGLView renderFrameQCAR");
            break;
        }
    }
    
    
}

//------------------------------------------------------------------------------
#pragma mark - Update augmentation params

- (void)setCurrentTrackableWith:(NSString *)trackable {
    // Check if we're still tracking the same trackable; if not, update and reset time
    if (![trackable isEqualToString:currentTrackable]) {
        NSLog(@"DEBUG: Switching to trackable %@", trackable);
        [currentTrackable setString: trackable];
        [self resetTime];
        [self selectShaderWithName:[[augmentationDict objectForKey:currentTrackable] objectForKey:@"shader"]];
        
        if ([trackable isEqualToString:@"Foxacid"]) {
            foxacid_state = PRE_FOXACID;
            foxacid_currentFrame = 0;
        } if ([trackable isEqualToString:@"Couple"]) {
            dolphin_state = PRE_DOLPHIN;
            dolphin_currentFrame = 0;
        } else if ([trackable isEqualToString:@"BlurredFaces"]) {
            blurredFaces_state = PRE_CAPTURE_FACE;
        } else if ([trackable isEqualToString:@"Kidnapper"]) {
            [self initPhantasmagoriaParams];
        } else if ([trackable isEqualToString:@"Cards"]) {
            emitter = [[AFSCardEmitterObject alloc] init];
        } else if ([trackable isEqualToString:@"Buffalo"]) {
            
        } else if ([trackable isEqualToString:@"RabbitDuck"]) {
            rdDelta = rdDeltaMagnitude;
            rdXPos = 0.0;
            rdYPos = 0.0;
            previousTime = CACurrentMediaTime();
        } else if ([trackable isEqualToString:@"1984"]
                   || [trackable isEqualToString:@"CyberMagicians"]
                   || [trackable isEqualToString:@"Egypt"]
                   || [trackable isEqualToString:@"Tank"]
                   || [trackable isEqualToString:@"CatDog"]) {
            videoData.targetPositiveDimensions.data[0] = 0.0f;
            videoData.targetPositiveDimensions.data[1] = 0.0f;
            videoPlaybackTime = VIDEO_PLAYBACK_CURRENT_POSITION;
            [videoPlayerHelper unload];
            NSString *videoFile = [[augmentationDict objectForKey:trackable] objectForKey:@"video"];
            if (NO == [videoPlayerHelper load:videoFile playImmediately:NO fromPosition:videoPlaybackTime]) {
                NSLog(@"Failed to load video file: %@", videoFile);
            }
        }
    }
}

- (void)initPhantasmagoriaParams {
    // Have to set scaling manually, outside of the loop
    // This is factor that gets multiplied with the overall factor
    // TODO: This is brittle
    //phScale[0][0] = 0.3 * 0.48;
    //phScale[0][1] = 0.3;
    phScale[0][0] = 0.4;
    phScale[0][1] = 0.4 * 0.96;
    phScale[1][0] = 0.4;
    phScale[1][1] = 0.4 * 0.90;
    
    // Set initial positions for my Bezier control points
    for (int i = 0; i < NUM_PHANTASMAGORIA_TEXTURES; i++) {
        // Set P0 and P3 as fixed for a given augmentation
        phP[i][0][0] = phP0MinX;
        phP[i][0][1] = [self randomFloatBetweenMin:phP0MinY andMax:phP0MaxY];
        phP[i][3][0] = phP3MaxX;
        phP[i][3][1] = [self randomFloatBetweenMin:phP3MinY andMax:phP3MaxY];
        
        // Setup the other values
        [self setupPhantasmagoriaParamFor:i];
    }
    
}

- (void)setupPhantasmagoriaParamFor:(int)phIndex {
    phTime[phIndex] = 0.0;
    phTimeOffset[phIndex] = [self randomFloatBetweenMin:phTimeOffsetMin andMax:phTimeOffsetMax];
    
    
    phP[phIndex][1][0] = phP[phIndex][0][0] + [self randomFloatBetweenMin:phP1MinOffsetX andMax:phP1MaxOffsetX];
    phP[phIndex][1][1] = phP[phIndex][0][1] + [self randomFloatBetweenMin:phP1MinOffsetY andMax:phP1MaxOffsetY];
    phP[phIndex][2][0] = phP[phIndex][3][0] + [self randomFloatBetweenMin:phP2MinOffsetX andMax:phP2MaxOffsetX];
    phP[phIndex][2][1] = phP[phIndex][3][1] + [self randomFloatBetweenMin:phP2MinOffsetY andMax:phP2MaxOffsetY];
    
    // Setup the initial position along Bezier curve
    phCurrentPos[phIndex][0] = powf(1 - phTime[phIndex], 3)*phP[phIndex][0][0] +
    3 * phTime[phIndex] * powf(1 - phTime[phIndex], 2) * phP[phIndex][1][0] +
    3 * powf(phTime[phIndex], 2) * (1 - phTime[phIndex]) * phP[phIndex][2][0] +
    powf(phTime[phIndex], 3)*phP[phIndex][3][0];
    phCurrentPos[phIndex][1] = powf(1 - phTime[phIndex], 3)*phP[phIndex][0][1] +
    3 * phTime[phIndex] * powf(1 - phTime[phIndex], 2) * phP[phIndex][1][1] +
    3 * powf(phTime[phIndex], 2) * (1 - phTime[phIndex]) * phP[phIndex][2][1] +
    powf(phTime[phIndex], 3)*phP[phIndex][3][1];
}

- (float)randomFloatBetweenMin:(float)min andMax:(float)max
{
    float range = max - min;
    return (((float) (arc4random() % ((unsigned)RAND_MAX + 1)) / RAND_MAX) * range) + min;
}

- (void)resetTime {
    time = 0;
    angle = 0;
    xAxis = 0;
    yAxis = 0;
    previousTime = CACurrentMediaTime();
}

- (void)updateTime {
    time += 0.1;
    angle += 15.0;

    // Update RabbitDuck params
    if ((CACurrentMediaTime() - previousTime) >= (1.0/rdFramesPerSecond)) {
        if ([currentTrackable isEqualToString:@"RabbitDuck"]) {
            if (rdXPos <= -76.0) {
                rdDelta = rdDeltaMagnitude;
            } else if (rdXPos >= 110.0) {
                rdDelta = -1.0f * rdDeltaMagnitude;
            }
            
            rdXPos += rdDelta;
            rdYPos = 30*sinf(0.1 * rdXPos) + 10.0;
        }

        previousTime = CACurrentMediaTime();
    }
    
    // Update Foxacid params
    if ((CACurrentMediaTime() - previousTime) >= (1.0/foxacid_FramesPerSecond) ) {
        foxacid_currentFrame += 1;
        foxacid_currentFrame = (foxacid_currentFrame)%foxacid_Frames;
        //foxacid_currentFrame = 0;
        previousTime = CACurrentMediaTime();
    }
    
    // Update Dolphin params
    if ((CACurrentMediaTime() - previousTime) >= (1.0/dolphin_FramesPerSecond) ) {
        dolphin_currentFrame += 1;
        dolphin_currentFrame = (dolphin_currentFrame)%dolphin_Frames;
        //foxacid_currentFrame = 0;
        previousTime = CACurrentMediaTime();
    }
    
    
}

- (void)updateBlurredFacesParams {
    time += 0.1;
    angle += 1.0;
    
    //foxacid_currentFrame += 1;
    switch (blurredFaces_state) {
        case PRE_CAPTURE_FACE: {
            alpha = 0.0;
            if ((CACurrentMediaTime() - previousTime) >= blurredFaces_preDelay) {
                previousTime = CACurrentMediaTime();
                blurredFaces_state = SETUP_CAPTURE_FACE;
                NSLog(@"Switching to SETUP_CAPTURE_FACE");
                //[afsImageTargetsViewController pauseAR];
                
            }
            break;
        }
        case SETUP_CAPTURE_FACE: {
            previousTime = CACurrentMediaTime();
            break;
        }
        case CAPTURE_FACE: {
            if (((CACurrentMediaTime() - previousTime) >= blurredFaces_preAlphaDelay) && (((CACurrentMediaTime() - previousTime) <= blurredFaces_captureDelay))) {
                alpha += 0.05;
                if (alpha >= 1.0) {
                    alpha = 1.0;
                }
            }
            
            if ((CACurrentMediaTime() - previousTime) >= blurredFaces_captureDelay ) {
                blurredFaces_state = PRE_AUGMENT_FACE;
                previousTime = CACurrentMediaTime();
                NSLog(@"Switching to PRE_AUGMENT_FACE");
                //[self teardownAVCapture];
            }
            
            break;
        }
        case PRE_AUGMENT_FACE: {
            blurredFaces_state = AUGMENT_FACE;
            previousTime = CACurrentMediaTime();
        }
        case AUGMENT_FACE:
            break;
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

- (void)updatePhantasmagoriaParams {
    for (int i = 0; i < NUM_PHANTASMAGORIA_TEXTURES; i++) {
        if ((phTime[i] >= 1.0) && (phTimeOffset[i] > 0.0)) {
            [self setupPhantasmagoriaParamFor:i];
            phTime[i] = 1.0;
            phTimeOffset[i] = -1.0 * phTimeOffset[i];
        } else if ((phTimeOffset[i] < 0.0) && (phTime[i] <= 0.0)) {
            [self setupPhantasmagoriaParamFor:i];
            phTime[i] = 0.0;
            phTimeOffset[i] = 1.0 * phTimeOffset[i];
        }else {
            phTime[i] += phTimeOffset[i];
        }
        
        // Update current position along Bezier curve
        phCurrentPos[i][0] = powf(1 - phTime[i], 3)*phP[i][0][0] +
                            3 * phTime[i] * powf(1 - phTime[i], 2) * phP[i][1][0] +
                            3 * powf(phTime[i], 2) * (1 - phTime[i]) * phP[i][2][0] +
                            powf(phTime[i], 3)*phP[i][3][0];
        phCurrentPos[i][1] = powf(1 - phTime[i], 3)*phP[i][0][1] +
                            3 * phTime[i] * powf(1 - phTime[i], 2) * phP[i][1][1] +
                            3 * powf(phTime[i], 2) * (1 - phTime[i]) * phP[i][2][1] +
                            powf(phTime[i], 3)*phP[i][3][1];
    }
}

- (void)updateDolphinParams {
    time += 0.1;
    angle += 1.0;
    //dolphin_currentFrame += 1;
    switch (dolphin_state) {
        case PRE_DOLPHIN:
            if ((CACurrentMediaTime() - previousTime) >= dolphin_preDelay) {
                previousTime = CACurrentMediaTime();
                dolphin_state = PLAYING_DOLPHIN;
            }
            break;
        case PLAYING_DOLPHIN:
            if ((CACurrentMediaTime() - previousTime) >= (1.0/dolphin_FramesPerSecond) ) {
                dolphin_currentFrame += 1;
                //dolphin_currentFrame = (dolphin_currentFrame)%dolphin_Frames;
                //dolphin_currentFrame = 0;
                previousTime = CACurrentMediaTime();
            }
            
            //NSLog(@"Current frame: %d", dolphin_currentFrame);
            if (dolphin_currentFrame == dolphin_Frames) {
                //NSLog(@"RESETTING");
                previousTime = CACurrentMediaTime();
                dolphin_state = POST_DOLPHIN;
            }
            break;
        case POST_DOLPHIN:
            if ((CACurrentMediaTime() - previousTime) >= dolphin_postDelay) {
                previousTime = CACurrentMediaTime();
                dolphin_state = PRE_DOLPHIN;
                dolphin_currentFrame = 0;
            }
            break;
    }
}

//------------------------------------------------------------------------------
#pragma mark - Front camera methods (not used right now)

- (void)setupFacesFBO
{
    facesFBOWidth = 512;
    facesFBOHeight = 512;
    
    glGetIntegerv(GL_FRAMEBUFFER_BINDING, &defaultFBO);
    
    glGenFramebuffers(1, &facesFBOHandle);
    glGenTextures(1, &facesFBOTexture);
    glGenRenderbuffers(1, &facesDepthBuffer);
    
    glBindFramebuffer(GL_FRAMEBUFFER, facesFBOHandle);
    
    glBindTexture(GL_TEXTURE_2D, facesFBOTexture);
    glTexImage2D( GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 facesFBOWidth, facesFBOHeight,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 NULL);
    
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, facesFBOTexture, 0);
    
    glBindRenderbuffer(GL_RENDERBUFFER, facesDepthBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT24_OES, facesFBOWidth, facesFBOHeight);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, facesDepthBuffer);
    
    // FBO status check
    GLenum status;
    status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    switch(status) {
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"FBO complete");
            break;
            
        case GL_FRAMEBUFFER_UNSUPPORTED:
            NSLog(@"FBO unsupported");
            break;
            
        default:
            /* programming error; will fail on all hardware */
            NSLog(@"Framebuffer Error");
            break;
    }
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);
}

- (void)renderFacesFBO
{
    glBindTexture(GL_TEXTURE_2D, 0);
    glEnable(GL_TEXTURE_2D);
    glBindFramebuffer(GL_FRAMEBUFFER, facesFBOHandle);
    
    glViewport(0, 0, facesFBOWidth, facesFBOHeight);
    //glClearColor(0.0f, 1.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    
    glBindFramebuffer(GL_FRAMEBUFFER, defaultFBO);
}

// Scale a point to the OpenGL coordinate system of -1 to 1
- (CGPoint) scalePoint:(CGPoint)point withExtent:(CGSize)extent andOffset:(CGPoint)offset {
    // Flip our given coordinates (so that the origin is LL rather than UL), shift so that we are centered around the Y axis, scale to be between -1 and 1, and offset by a given number of pixels in the original coordinate system
    return CGPointMake(((extent.width - (point.x - offset.x)) - (extent.width/2.0f))/(extent.width/2.0f),
                       ((extent.height - (point.y - offset.y)) - (extent.height/2.0f))/(extent.height/2.0f));
}

// Scale a point to the OpenGL coordinate system of -1 to 1
- (CGPoint) noResetScalePoint:(CGPoint)point withExtent:(CGSize)extent andOffset:(CGPoint)offset {
    // Flip our given coordinates (so that the origin is LL rather than UL), shift so that we are centered around the Y axis, scale to be between -1 and 1, and offset by a given number of pixels in the original coordinate system
    return CGPointMake((((point.x + offset.x)) - (extent.width/2.0f))/(extent.width/2.0f),
                       (((point.y + offset.y)) - (extent.height/2.0f))/(extent.height/2.0f));
}

- (NSNumber *) exifOrientation: (UIDeviceOrientation) orientation
{
	int exifOrientation;
    /* kCGImagePropertyOrientation values
     The intended display orientation of the image. If present, this key is a CFNumber value with the same value as defined
     by the TIFF and EXIF specifications -- see enumeration of integer constants.
     The value specified where the origin (0,0) of the image is located. If not present, a value of 1 is assumed.
     
     used when calling featuresInImage: options: The value for this key is an integer NSNumber from 1..8 as found in kCGImagePropertyOrientation.
     If present, the detection will be done based on that orientation but the coordinates in the returned features will still be based on those of the image. */
    
	enum {
		PHOTOS_EXIF_0ROW_TOP_0COL_LEFT			= 1, //   1  =  0th row is at the top, and 0th column is on the left (THE DEFAULT).
		PHOTOS_EXIF_0ROW_TOP_0COL_RIGHT			= 2, //   2  =  0th row is at the top, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT      = 3, //   3  =  0th row is at the bottom, and 0th column is on the right.
		PHOTOS_EXIF_0ROW_BOTTOM_0COL_LEFT       = 4, //   4  =  0th row is at the bottom, and 0th column is on the left.
		PHOTOS_EXIF_0ROW_LEFT_0COL_TOP          = 5, //   5  =  0th row is on the left, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP         = 6, //   6  =  0th row is on the right, and 0th column is the top.
		PHOTOS_EXIF_0ROW_RIGHT_0COL_BOTTOM      = 7, //   7  =  0th row is on the right, and 0th column is the bottom.
		PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM       = 8  //   8  =  0th row is on the left, and 0th column is the bottom.
	};
	
	switch (orientation) {
		case UIDeviceOrientationPortraitUpsideDown:  // Device oriented vertically, home button on the top
			exifOrientation = PHOTOS_EXIF_0ROW_LEFT_0COL_BOTTOM;
			break;
		case UIDeviceOrientationLandscapeLeft:       // Device oriented horizontally, home button on the right
			if (self.isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			break;
		case UIDeviceOrientationLandscapeRight:      // Device oriented horizontally, home button on the left
			if (self.isUsingFrontFacingCamera)
				exifOrientation = PHOTOS_EXIF_0ROW_TOP_0COL_LEFT;
			else
				exifOrientation = PHOTOS_EXIF_0ROW_BOTTOM_0COL_RIGHT;
			break;
		case UIDeviceOrientationPortrait:            // Device oriented vertically, home button on the bottom
		default:
			exifOrientation = PHOTOS_EXIF_0ROW_RIGHT_0COL_TOP;
			break;
	}
    return [NSNumber numberWithInt:exifOrientation];
}

// find where the video box is positioned within the preview layer based on the video size and gravity
+ (CGRect)videoPreviewBoxForGravity:(NSString *)gravity
                          frameSize:(CGSize)frameSize
                       apertureSize:(CGSize)apertureSize
{
    CGFloat apertureRatio = apertureSize.height / apertureSize.width;
    CGFloat viewRatio = frameSize.width / frameSize.height;
    
    CGSize size = CGSizeZero;
    if ([gravity isEqualToString:AVLayerVideoGravityResizeAspectFill]) {
        if (viewRatio > apertureRatio) {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        } else {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResizeAspect]) {
        if (viewRatio > apertureRatio) {
            size.width = apertureSize.height * (frameSize.height / apertureSize.width);
            size.height = frameSize.height;
        } else {
            size.width = frameSize.width;
            size.height = apertureSize.width * (frameSize.width / apertureSize.height);
        }
    } else if ([gravity isEqualToString:AVLayerVideoGravityResize]) {
        size.width = frameSize.width;
        size.height = frameSize.height;
    }
	
	CGRect videoBox;
	videoBox.size = size;
	if (size.width < frameSize.width)
		videoBox.origin.x = (frameSize.width - size.width) / 2;
	else
		videoBox.origin.x = (size.width - frameSize.width) / 2;
	
	if ( size.height < frameSize.height )
		videoBox.origin.y = (frameSize.height - size.height) / 2;
	else
		videoBox.origin.y = (size.height - frameSize.height) / 2;
    
	return videoBox;
}


// called asynchronously as the capture output is capturing sample buffers, this method asks the face detector
// to detect features and for each draw the green border in a layer and set appropriate orientation
- (void)drawFaces:(NSArray *)features
      forVideoBox:(CGRect)clearAperture
      orientation:(UIDeviceOrientation)orientation
{
	NSArray *sublayers = [NSArray arrayWithArray:[self.videoPreviewLayer sublayers]];
	NSInteger sublayersCount = [sublayers count], currentSublayer = 0;
	NSInteger featuresCount = [features count], currentFeature = 0;
	
	[CATransaction begin];
	[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
	
	// hide all the face layers
	for ( CALayer *layer in sublayers ) {
		if ( [[layer name] isEqualToString:@"FaceLayer"] )
			[layer setHidden:YES];
	}
	
	if ( featuresCount == 0 ) {
		[CATransaction commit];
		return; // early bail.
	}
    
	CGSize parentFrameSize = [self.videoPreviewLayer frame].size;
	NSString *gravity = [self.videoPreviewLayer videoGravity];
	BOOL isMirrored = [self.videoPreviewLayer isMirrored];
	CGRect previewBox = [AFSImageTargetsEAGLView videoPreviewBoxForGravity:gravity
                                                        frameSize:parentFrameSize
                                                     apertureSize:clearAperture.size];
	
	for ( CIFaceFeature *ff in features ) {
        NSLog(@"HAS LEFT EYE POSITION: %d", ff.hasLeftEyePosition);
        NSLog(@"HAS LEFT EYE POSITION x: %f", ff.leftEyePosition.x);
        
        if ([ff hasLeftEyePosition]) {
            self.leftEyePoint = ff.leftEyePosition;
        }
        
        if ([ff hasRightEyePosition]) {
            self.rightEyePoint = ff.rightEyePosition;
        }
        
		// find the correct position for the square layer within the previewLayer
		// the feature box originates in the bottom left of the video frame.
		// (Bottom right if mirroring is turned on)
		CGRect tmpFaceRect = [ff bounds];
        self.faceRect = tmpFaceRect;
        NSLog(@"IN DRAW FACES, BEFORE TRANSFORMATIONS: tmpFaceRect: %@", NSStringFromCGRect(tmpFaceRect));
        
		// flip preview width and height
		CGFloat temp = tmpFaceRect.size.width;
		tmpFaceRect.size.width = tmpFaceRect.size.height;
		tmpFaceRect.size.height = temp;
		temp = tmpFaceRect.origin.x;
		tmpFaceRect.origin.x = tmpFaceRect.origin.y;
		tmpFaceRect.origin.y = temp;
		// scale coordinates so they fit in the preview box, which may be scaled
		CGFloat widthScaleBy = previewBox.size.width / clearAperture.size.height;
		CGFloat heightScaleBy = previewBox.size.height / clearAperture.size.width;
		tmpFaceRect.size.width *= widthScaleBy;
		tmpFaceRect.size.height *= heightScaleBy;
		tmpFaceRect.origin.x *= widthScaleBy;
		tmpFaceRect.origin.y *= heightScaleBy;
        
        
		if ( isMirrored )
			tmpFaceRect = CGRectOffset(tmpFaceRect, previewBox.origin.x + previewBox.size.width - tmpFaceRect.size.width - (tmpFaceRect.origin.x * 2), previewBox.origin.y);
		else
			tmpFaceRect = CGRectOffset(tmpFaceRect, previewBox.origin.x, previewBox.origin.y);
		
        
        NSLog(@"IN DRAW FACES, faceRect: %@", NSStringFromCGRect(self.faceRect));
        NSLog(@"IN DRAW FACES, tmpFaceRect: %@", NSStringFromCGRect(tmpFaceRect));
        
		CALayer *featureLayer = nil;
		
		// re-use an existing layer if possible
		while ( !featureLayer && (currentSublayer < sublayersCount) ) {
			CALayer *currentLayer = [sublayers objectAtIndex:currentSublayer++];
			if ( [[currentLayer name] isEqualToString:@"FaceLayer"] ) {
				featureLayer = currentLayer;
				[currentLayer setHidden:NO];
			}
		}
		
		// create a new one if necessary
		if ( !featureLayer ) {
			featureLayer = [[CALayer alloc]init];
			//featureLayer.contents = (id)self.borderImage.CGImage;
            featureLayer.borderWidth = 3.0;
            featureLayer.frame = self.faceRect;
			[featureLayer setName:@"FaceLayer"];
			[self.videoPreviewLayer addSublayer:featureLayer];
			//featureLayer = nil;
		}
		[featureLayer setFrame:tmpFaceRect];
        
		
		switch (orientation) {
			case UIDeviceOrientationPortrait:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(0.))];
				break;
			case UIDeviceOrientationPortraitUpsideDown:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(180.))];
				break;
			case UIDeviceOrientationLandscapeLeft:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(90.))];
				break;
			case UIDeviceOrientationLandscapeRight:
				[featureLayer setAffineTransform:CGAffineTransformMakeRotation(DegreesToRadians(-90.))];
				break;
			case UIDeviceOrientationFaceUp:
			case UIDeviceOrientationFaceDown:
			default:
				break; // leave the layer in its last known orientation
		}
		currentFeature++;
	}
    
	[CATransaction commit];
}



- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection
{
    /*
    if (([connection videoOrientation] == AVCaptureVideoOrientationLandscapeLeft) || ([connection videoOrientation] == AVCaptureVideoOrientationLandscapeRight)) {
        NSLog(@"LANDSCAPE");
    } else {
        NSLog(@"PORTRAIT");
    }
     */
    
	// get the image
	CVPixelBufferRef pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
	CFDictionaryRef attachments = CMCopyDictionaryOfAttachments(kCFAllocatorDefault, sampleBuffer, kCMAttachmentMode_ShouldPropagate);
	CIImage *ciImage = [[CIImage alloc] initWithCVPixelBuffer:pixelBuffer
                                                      options:(__bridge NSDictionary *)attachments];
    self.currentFrontImage = [ciImage copy];
    //self.currentFrontImage = [self.currentFrontImage imageByApplyingTransform:CGAffineTransformTranslate(CGAffineTransformMakeScale(-1, 1), 0, self.currentFrontImage.extent.size.width)];
    
	if (attachments) {
		CFRelease(attachments);
    }
    
    // make sure your device orientation is not locked.
	UIDeviceOrientation curDeviceOrientation = [[UIDevice currentDevice] orientation];
    if ([connection isVideoOrientationSupported])
    {
        
        if (curDeviceOrientation == UIDeviceOrientationPortrait) {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortrait;
            [connection setVideoOrientation:orientation];
        } else if (curDeviceOrientation == UIDeviceOrientationLandscapeLeft) {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeLeft;
            [connection setVideoOrientation:orientation];
        } else if (curDeviceOrientation == UIDeviceOrientationLandscapeRight) {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
            [connection setVideoOrientation:orientation];
        } else if (curDeviceOrientation == UIDeviceOrientationPortraitUpsideDown) {
            AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationPortraitUpsideDown;
            [connection setVideoOrientation:orientation];
        }
        
    }
	
    
//    // get the clean aperture
//    // the clean aperture is a rectangle that defines the portion of the encoded pixel dimensions
//    // that represents image data valid for display.
//	CMFormatDescriptionRef fdesc = CMSampleBufferGetFormatDescription(sampleBuffer);
//	CGRect cleanAperture = CMVideoFormatDescriptionGetCleanAperture(fdesc, false /*originIsTopLeft == false*/);

    /*
	dispatch_async(dispatch_get_main_queue(), ^(void) {
		[self drawFaces:features
            forVideoBox:cleanAperture
            orientation:curDeviceOrientation];
	});
     */
}

// clean up capture setup
- (void)teardownAVCapture
{
    [session stopRunning];
    
    [self.videoDataOutput release];
	self.videoDataOutput = nil;
    
	if (self.videoDataOutputQueue) {
		dispatch_release(self.videoDataOutputQueue);
    }
    [self.videoDataOutputQueue release];
    self.videoDataOutputQueue = nil;
    
	[self.videoPreviewLayer removeFromSuperlayer];
    [self.videoPreviewLayer release];
	self.videoPreviewLayer = nil;
    
    [session release];
    session = nil;
}

//------------------------------------------------------------------------------
#pragma mark - Tracking timer methods

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
    //NSLog(@"DEBUG: Shader name: %@", shaderName);
    shaderProgramID = [SampleApplicationShaderUtils
                       createProgramWithVertexShaderFileName:[NSString stringWithFormat:@"%@.vertsh", shaderName]
                       fragmentShaderFileName:[NSString stringWithFormat:@"%@.fragsh", shaderName]];
    
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
        alphaHandle = glGetUniformLocation(shaderProgramID, "alpha");
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
        
        // setup our Faces FBO
        [self setupFacesFBO];
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
