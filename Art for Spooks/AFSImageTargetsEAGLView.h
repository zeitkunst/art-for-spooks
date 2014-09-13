//  Portions of this file are based on Qualcomm Vuforia Sample code.
//
//  Copyright (c) 2014 Nicholas A. Knouf
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

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
