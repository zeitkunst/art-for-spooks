/*===============================================================================
Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc. All Rights Reserved.

Vuforia is a trademark of QUALCOMM Incorporated, registered in the United States 
and other countries. Trademarks of QUALCOMM Incorporated are used with permission.
===============================================================================*/

#import <UIKit/UIKit.h>

#import <QCAR/UIGLViewProtocol.h>

#import "Texture.h"
#import "SampleApplicationSession.h"
#import "SampleApplication3DModel.h"
#import "VideoPlayerHelper.h"

#define NUM_AUGMENTATION_TEXTURES 5
#define NUM_PHANTASMAGORIA_TEXTURES 2

@class AFSImageTargetsViewController;

// EAGLView is a subclass of UIView and conforms to the informal protocol
// UIGLViewProtocol
@interface AFSImageTargetsEAGLView : UIView <UIGLViewProtocol, AVCaptureVideoDataOutputSampleBufferDelegate> {
@private
    // OpenGL ES context
    EAGLContext *context;
    
    // The OpenGL ES names for the framebuffer and renderbuffers used to render
    // to this view
    GLuint defaultFramebuffer;
    GLuint colorRenderbuffer;
    GLuint depthRenderbuffer;

    // Shader handles
    GLuint shaderProgramID;
    GLint vertexHandle;
    GLint normalHandle;
    GLint textureCoordHandle;
    GLint mvpMatrixHandle;
    GLint texSampler2DHandle;
    GLint resolutionHandle;
    GLint timeHandle;
    GLint alphaHandle;
    GLint frameRowHandle;
    GLint frameColumnHandle;
    GLfloat time;
    GLfloat alpha;
    GLfloat resolution[2];
    
    double previousTime;
    
    float angle;
    float xAxis;
    float yAxis;

    SampleApplicationSession * vapp;
    
    AFSImageTargetsViewController *afsImageTargetsViewController;
    
    VideoPlayerHelper* videoPlayerHelper;
    float videoPlaybackTime;
        
    // Lock to synchronise data that is (potentially) accessed concurrently
    NSLock* dataLock;
    
    // Timer to pause on-texture video playback after tracking has been lost.
    // Note: written/read on two threads, but never concurrently
    NSTimer* trackingLostTimer;
    
    AVCaptureSession *session;
}

- (id)initWithFrame:(CGRect)frame rootViewController:(AFSImageTargetsViewController *) rootViewController appSession:(SampleApplicationSession *) app;

- (void)finishOpenGLESCommands;
- (void)freeOpenGLESResources;
@end
