/* face-authentification.c
 *
 * Copyright (C) 2009-2011  Supersonic Imagine
 *
 * This library is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this library.  If not, see <http://www.gnu.org/licenses/>.
 *
 * Author:
 * 	Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

#include <glib.h>

#include "face-authentification.h"
#include "opencvWebcam.h"
#include "detector.h"
#include "webcamImagePaint.h"
#include "verifier.h"

struct _XSAAFaceAuthentificationWebcam
{
    opencvWebcam* m_pWebcam;
};

struct _XSAAFaceAuthentificationWebcamImagePaint
{
    webcamImagePaint* m_pWebcamImagePaint;
};

struct _XSAAFaceAuthentificationDetector
{
    detector* m_pDetector;
};

struct _XSAAFaceAuthentificationVerifier
{
    verifier* m_pVerifier;
};

XSAAFaceAuthentificationWebcam*
xsaa_face_authentification_webcam_new ()
{
    XSAAFaceAuthentificationWebcam* self = g_slice_new0 (XSAAFaceAuthentificationWebcam);
    self->m_pWebcam = new opencvWebcam ();
    return self;
}

void
xsaa_face_authentification_webcam_free (XSAAFaceAuthentificationWebcam* self)
{
    delete self->m_pWebcam; self->m_pWebcam = 0;
    g_slice_free (XSAAFaceAuthentificationWebcam, self);
}

IplImage*
xsaa_face_authentification_webcam_query_frame  (XSAAFaceAuthentificationWebcam* self)
{
    return self->m_pWebcam->queryFrame ();
}

int
xsaa_face_authentification_webcam_start_camera (XSAAFaceAuthentificationWebcam* self)
{
    return self->m_pWebcam->startCamera ();
}

void
xsaa_face_authentification_webcam_stop_camera  (XSAAFaceAuthentificationWebcam* self)
{
    self->m_pWebcam->stopCamera ();
}

XSAAFaceAuthentificationWebcamImagePaint*
xsaa_face_authentification_webcam_image_paint_new ()
{
    XSAAFaceAuthentificationWebcamImagePaint* self = g_slice_new0 (XSAAFaceAuthentificationWebcamImagePaint);
    self->m_pWebcamImagePaint = new webcamImagePaint ();
    return self;
}

void
xsaa_face_authentification_webcam_image_paint_free (XSAAFaceAuthentificationWebcamImagePaint* self)
{
    delete self->m_pWebcamImagePaint; self->m_pWebcamImagePaint = 0;
    g_slice_free (XSAAFaceAuthentificationWebcamImagePaint, self);
}

void
xsaa_face_authentification_webcam_image_paint_cyclops (XSAAFaceAuthentificationWebcamImagePaint* self,
                                                       IplImage* inImage, CvPoint inLE, CvPoint inRE)
{
    self->m_pWebcamImagePaint->paintCyclops (inImage, inLE, inRE);
}

void
xsaa_face_authentification_webcam_image_paint_ellipse (XSAAFaceAuthentificationWebcamImagePaint* self,
                                                       IplImage* inImage, CvPoint inLE, CvPoint inRE)
{
    self->m_pWebcamImagePaint->paintEllipse (inImage, inLE, inRE);
}

XSAAFaceAuthentificationDetector*
xsaa_face_authentification_detector_new ()
{
    XSAAFaceAuthentificationDetector* self = g_slice_new0 (XSAAFaceAuthentificationDetector);
    self->m_pDetector = new detector ();
    return self;
}

void
xsaa_face_authentification_detector_free (XSAAFaceAuthentificationDetector* self)
{
    delete self->m_pDetector; self->m_pDetector = 0;
    g_slice_free (XSAAFaceAuthentificationDetector, self);
}

IplImage**
xsaa_face_authentification_detector_get_clipped_face (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->clippedFace;
}

int
xsaa_face_authentification_detector_get_message_index (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->messageIndex;
}

IplImage**
xsaa_face_authentification_detector_return_clipped_face (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->returnClipedFace ();
}

void
xsaa_face_authentification_detector_start_clip_face (XSAAFaceAuthentificationDetector* self, int inNum)
{
    self->m_pDetector->startClipFace (inNum);
}

void
xsaa_face_authentification_detector_stop_clip_face (XSAAFaceAuthentificationDetector* self)
{
    self->m_pDetector->stopClipFace ();
}

int
xsaa_face_authentification_detector_finished_clip_face (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->finishedClipFace ();
}

void
xsaa_face_authentification_detector_run_detector (XSAAFaceAuthentificationDetector* self, IplImage* inInput)
{
    self->m_pDetector->runDetector (inInput);
}

int
xsaa_face_authentification_detector_query_message (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->queryMessage ();
}

IplImage*
xsaa_face_authentification_detector_clip_face (XSAAFaceAuthentificationDetector* self, IplImage* inInputImage)
{
    return self->m_pDetector->clipFace (inInputImage);
}

int
xsaa_face_authentification_detector_sucessfull (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->detectorSuccessful ();
}

void
xsaa_face_authentification_detector_get_eyes_information (XSAAFaceAuthentificationDetector* self,
                                                          XSAAFaceAuthentificationEyes* eyes)
{
    eyes->le.x = self->m_pDetector->eyesInformation.LE.x;
    eyes->le.y = self->m_pDetector->eyesInformation.LE.y;
    eyes->re.x = self->m_pDetector->eyesInformation.RE.x;
    eyes->re.y = self->m_pDetector->eyesInformation.RE.y;
    eyes->length = self->m_pDetector->eyesInformation.Length;
}

void
xsaa_face_authentification_detector_run_eyes_detector (XSAAFaceAuthentificationDetector* self,
                                                      IplImage* inInput, IplImage* inFullImage,
                                                      CvPoint inLe)
{
    self->m_pDetector->runEyesDetector (inInput, inFullImage, inLe);
}

int
xsaa_face_authentification_detector_check_eyes_detected (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->checkEyeDetected ();
}

void
xsaa_face_authentification_detector_get_face_information (XSAAFaceAuthentificationDetector* self,
                                                          XSAAFaceAuthentificationFace* face)
{
    face->lt = self->m_pDetector->faceInformation.LT;
    face->rb = self->m_pDetector->faceInformation.RB;
    face->width = self->m_pDetector->faceInformation.Width;
    face->height = self->m_pDetector->faceInformation.Height;
}

void
xsaa_face_authentification_detector_run_face_detector   (XSAAFaceAuthentificationDetector* self, IplImage* inInput)
{
    self->m_pDetector->runFaceDetector (inInput);
}

IplImage*
xsaa_face_authentification_detector_clip_detected_face  (XSAAFaceAuthentificationDetector* self, IplImage* inInputImage)
{
    return self->m_pDetector->clipDetectedFace (inInputImage);
}

int
xsaa_face_authentification_detector_check_face_detected (XSAAFaceAuthentificationDetector* self)
{
    return self->m_pDetector->checkFaceDetected ();
}

XSAAFaceAuthentificationVerifier*
xsaa_face_authentification_verifier_new ()
{
    XSAAFaceAuthentificationVerifier* self = g_slice_new0 (XSAAFaceAuthentificationVerifier);
    self->m_pVerifier = new verifier ();
    return self;
}

XSAAFaceAuthentificationVerifier*
xsaa_face_authentification_verifier_new_for_uid (uid_t inUID)
{
    XSAAFaceAuthentificationVerifier* self = g_slice_new0 (XSAAFaceAuthentificationVerifier);
    self->m_pVerifier = new verifier (inUID);
    return self;
}

void
xsaa_face_authentification_verifier_free (XSAAFaceAuthentificationVerifier* self)
{
    delete self->m_pVerifier; self->m_pVerifier = 0;
    g_slice_free (XSAAFaceAuthentificationVerifier, self);
}

void
xsaa_face_authentification_verifier_create_biometric_models (XSAAFaceAuthentificationVerifier* self, char* inName)
{
    self->m_pVerifier->createBiometricModels (inName);
}

void
xsaa_face_authentification_verifier_add_face_set (XSAAFaceAuthentificationVerifier* self, IplImage** inSets, int inSizeSets)
{
    self->m_pVerifier->addFaceSet (inSets, inSizeSets);
}

void
xsaa_face_authentification_verifier_remove_face_set (XSAAFaceAuthentificationVerifier* self, char* inName)
{
    self->m_pVerifier->removeFaceSet (inName);
}

XSAAFaceAuthentificationFaceSetFace*
xsaa_face_authentification_verifier_get_face_set (XSAAFaceAuthentificationVerifier* self)
{
    return (XSAAFaceAuthentificationFaceSetFace*)self->m_pVerifier->getFaceSet ();
}

int
xsaa_face_authentification_verifier_verify_face (XSAAFaceAuthentificationVerifier* self, IplImage* inImage)
{
    return self->m_pVerifier->verifyFace (inImage);
}

const char*
xsaa_face_authentification_verifier_get_faces_directory (XSAAFaceAuthentificationVerifier* self)
{
    return self->m_pVerifier->facesDirectory.c_str ();
}

const char*
xsaa_face_authentification_verifier_get_model_directory (XSAAFaceAuthentificationVerifier* self)
{
    return self->m_pVerifier->modelDirectory.c_str ();
}

const char*
xsaa_face_authentification_verifier_get_config_directory (XSAAFaceAuthentificationVerifier* self)
{
    return self->m_pVerifier->configDirectory.c_str ();
}

