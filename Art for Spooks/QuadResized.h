/*==============================================================================
 Copyright (c) 2012-2014 Qualcomm Connected Experiences, Inc.
 All Rights Reserved.
 ==============================================================================*/

#ifndef _QCAR_QUAD_RESIZED_H_
#define _QCAR_QUAD_RESIZED_H_


#define NUM_QUAD_VERTEX 4
#define NUM_QUAD_INDEX 6


static const float quadVertices[NUM_QUAD_VERTEX * 3] =
{
    -34.00f,  -28.00f,  0.0f,
    34.00f,  -28.00f,  0.0f,
    34.00f,   27.00f,  0.0f,
    -34.00f,   27.00f,  0.0f,
};

static const float quadTexCoords[NUM_QUAD_VERTEX * 2] =
{
    0, 0,
    1, 0,
    1, 1,
    0, 1,
};

static const float quadNormals[NUM_QUAD_VERTEX * 3] =
{
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    0, 0, 1,
    
};

static const unsigned short quadIndices[NUM_QUAD_INDEX] =
{
    0,  1,  2,  0,  2,  3,
};


#endif // _QC_AR_QUAD_RESIZED_H_
