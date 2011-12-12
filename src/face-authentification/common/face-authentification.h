/* face-authentification.h
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

#include <sys/types.h>
#include <cv.h>
#include "pam_face_defines.h"

#ifndef __XSAA_FACE_AUTHENTIFICATION_H__
#define __XSAA_FACE_AUTHENTIFICATION_H__

#ifdef __cplusplus
extern "C"
{
#endif
    typedef struct _XSAAFaceAuthentificationWebcam XSAAFaceAuthentificationWebcam;

    XSAAFaceAuthentificationWebcam* xsaa_face_authentification_webcam_new ();
    void xsaa_face_authentification_webcam_free (XSAAFaceAuthentificationWebcam* self);

    IplImage* xsaa_face_authentification_webcam_query_frame  (XSAAFaceAuthentificationWebcam* self);
    int       xsaa_face_authentification_webcam_start_camera (XSAAFaceAuthentificationWebcam* self);
    void      xsaa_face_authentification_webcam_stop_camera  (XSAAFaceAuthentificationWebcam* self);

    typedef struct _XSAAFaceAuthentificationWebcamImagePaint XSAAFaceAuthentificationWebcamImagePaint;

    XSAAFaceAuthentificationWebcamImagePaint* xsaa_face_authentification_webcam_image_paint_new ();
    void xsaa_face_authentification_webcam_image_paint_free (XSAAFaceAuthentificationWebcamImagePaint* self);

    void xsaa_face_authentification_webcam_image_paint_cyclops (XSAAFaceAuthentificationWebcamImagePaint* self,
                                                                IplImage* inImage, CvPoint inLE, CvPoint inRE);
    void xsaa_face_authentification_webcam_image_paint_ellipse (XSAAFaceAuthentificationWebcamImagePaint* self,
                                                                IplImage* inImage, CvPoint inLE, CvPoint inRE);

    struct _XSAAFaceAuthentificationEyes
    {
        CvPoint le;
        CvPoint re;
        int length;
    };

    struct _XSAAFaceAuthentificationFace
    {
        CvPoint lt;
        CvPoint rb;
        int width;
        int height;
    } ;

    typedef struct _XSAAFaceAuthentificationEyes XSAAFaceAuthentificationEyes;
    typedef struct _XSAAFaceAuthentificationFace XSAAFaceAuthentificationFace;
    typedef struct _XSAAFaceAuthentificationDetector XSAAFaceAuthentificationDetector;

    XSAAFaceAuthentificationDetector* xsaa_face_authentification_detector_new ();
    void xsaa_face_authentification_detector_free (XSAAFaceAuthentificationDetector* self);

    IplImage**  xsaa_face_authentification_detector_get_clipped_face    (XSAAFaceAuthentificationDetector* self);
    int         xsaa_face_authentification_detector_get_message_index   (XSAAFaceAuthentificationDetector* self);
    IplImage**  xsaa_face_authentification_detector_return_clipped_face (XSAAFaceAuthentificationDetector* self);
    void        xsaa_face_authentification_detector_start_clip_face     (XSAAFaceAuthentificationDetector* self,
                                                                         int inNum);
    void        xsaa_face_authentification_detector_stop_clip_face      (XSAAFaceAuthentificationDetector* self);
    int         xsaa_face_authentification_detector_finished_clip_face  (XSAAFaceAuthentificationDetector* self);
    void        xsaa_face_authentification_detector_run_detector        (XSAAFaceAuthentificationDetector* self,
                                                                         IplImage* inInput);
    const char* xsaa_face_authentification_detector_query_message       (XSAAFaceAuthentificationDetector* self);
    IplImage*   xsaa_face_authentification_detector_clip_face           (XSAAFaceAuthentificationDetector* self,
                                                                         IplImage* inInputImage);
    int         xsaa_face_authentification_detector_sucessfull          (XSAAFaceAuthentificationDetector* self);

    void        xsaa_face_authentification_detector_get_eyes_information (XSAAFaceAuthentificationDetector* self,
                                                                          XSAAFaceAuthentificationEyes* eyes);
    void        xsaa_face_authentification_detector_run_eyes_detector   (XSAAFaceAuthentificationDetector* self,
                                                                         IplImage* inInput, IplImage* inFullImage,
                                                                         CvPoint inLe);
    int         xsaa_face_authentification_detector_check_eyes_detected (XSAAFaceAuthentificationDetector* self);

    void        xsaa_face_authentification_detector_get_face_information (XSAAFaceAuthentificationDetector* self,
                                                                          XSAAFaceAuthentificationFace* face);
    void        xsaa_face_authentification_detector_run_face_detector   (XSAAFaceAuthentificationDetector* self,
                                                                         IplImage* inInput);
    IplImage*   xsaa_face_authentification_detector_clip_detected_face  (XSAAFaceAuthentificationDetector* self,
                                                                         IplImage* inInputImage);
    int         xsaa_face_authentification_detector_check_face_detected (XSAAFaceAuthentificationDetector* self);

    typedef struct _XSAAFaceAuthentificationFaceSetFace XSAAFaceAuthentificationFaceSetFace;
    typedef struct _XSAAFaceAuthentificationFaceSetImages XSAAFaceAuthentificationFaceSetImages;
    typedef struct _XSAAFaceAuthentificationVerifier XSAAFaceAuthentificationVerifier;

    struct _XSAAFaceAuthentificationFaceSetImages
    {
        IplImage** faces;
        int count;
    };

    struct _XSAAFaceAuthentificationFaceSetFace
    {
        char**                                 name;
        XSAAFaceAuthentificationFaceSetImages* images;
        char**                                 file_paths;
        int                                    count;
    };

    XSAAFaceAuthentificationVerifier* xsaa_face_authentification_verifier_new ();
    XSAAFaceAuthentificationVerifier* xsaa_face_authentification_verifier_new_for_uid (uid_t inUID);
    void xsaa_face_authentification_verifier_free (XSAAFaceAuthentificationVerifier* self);

    void xsaa_face_authentification_verifier_create_biometric_models (XSAAFaceAuthentificationVerifier* self,
                                                                      char* inName);
    void xsaa_face_authentification_verifier_add_face_set            (XSAAFaceAuthentificationVerifier* self,
                                                                      IplImage** inSets, int inSizeSets);
    void xsaa_face_authentification_verifier_remove_face_set         (XSAAFaceAuthentificationVerifier* self,
                                                                      char* inName);

    XSAAFaceAuthentificationFaceSetFace* xsaa_face_authentification_verifier_get_face_set (XSAAFaceAuthentificationVerifier* self);
    int xsaa_face_authentification_verifier_verify_face              (XSAAFaceAuthentificationVerifier* self,
                                                                      IplImage* inImage);

    const char* xsaa_face_authentification_verifier_get_faces_directory  (XSAAFaceAuthentificationVerifier* self);
    const char* xsaa_face_authentification_verifier_get_model_directory  (XSAAFaceAuthentificationVerifier* self);
    const char* xsaa_face_authentification_verifier_get_config_directory (XSAAFaceAuthentificationVerifier* self);

#ifdef __cplusplus
}
#endif
#endif /* __XSAA_FACE_AUTHENTIFICATION_H__ */

