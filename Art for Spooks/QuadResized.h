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
