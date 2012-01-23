/* face-authentification.h generated by valac 0.12.1, the Vala compiler, do not modify */


#ifndef __FACE_AUTHENTIFICATION_H__
#define __FACE_AUTHENTIFICATION_H__

#include <glib.h>
#include <sys/types.h>
#include <stdlib.h>
#include <string.h>
#include <cv.h>
#include <float.h>
#include <math.h>
#include <glib-object.h>

G_BEGIN_DECLS


#define XSAA_FACE_AUTHENTIFICATION_TYPE_STATUS (xsaa_face_authentification_status_get_type ())

#define XSAA_FACE_AUTHENTIFICATION_TYPE_MACE_DEFAULT (xsaa_face_authentification_mace_default_get_type ())

#define XSAA_FACE_AUTHENTIFICATION_TYPE_WEBCAM (xsaa_face_authentification_webcam_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_WEBCAM(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_WEBCAM, XSAAFaceAuthentificationWebcam))
#define XSAA_FACE_AUTHENTIFICATION_WEBCAM_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_WEBCAM, XSAAFaceAuthentificationWebcamClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_WEBCAM(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_WEBCAM))
#define XSAA_FACE_AUTHENTIFICATION_IS_WEBCAM_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_WEBCAM))
#define XSAA_FACE_AUTHENTIFICATION_WEBCAM_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_WEBCAM, XSAAFaceAuthentificationWebcamClass))

typedef struct _XSAAFaceAuthentificationWebcam XSAAFaceAuthentificationWebcam;
typedef struct _XSAAFaceAuthentificationWebcamClass XSAAFaceAuthentificationWebcamClass;
typedef struct _XSAAFaceAuthentificationWebcamPrivate XSAAFaceAuthentificationWebcamPrivate;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_TRACKER (xsaa_face_authentification_tracker_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_TRACKER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_TRACKER, XSAAFaceAuthentificationTracker))
#define XSAA_FACE_AUTHENTIFICATION_TRACKER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_TRACKER, XSAAFaceAuthentificationTrackerClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_TRACKER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_TRACKER))
#define XSAA_FACE_AUTHENTIFICATION_IS_TRACKER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_TRACKER))
#define XSAA_FACE_AUTHENTIFICATION_TRACKER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_TRACKER, XSAAFaceAuthentificationTrackerClass))

typedef struct _XSAAFaceAuthentificationTracker XSAAFaceAuthentificationTracker;
typedef struct _XSAAFaceAuthentificationTrackerClass XSAAFaceAuthentificationTrackerClass;
typedef struct _XSAAFaceAuthentificationTrackerPrivate XSAAFaceAuthentificationTrackerPrivate;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_EYES (xsaa_face_authentification_eyes_get_type ())
typedef struct _XSAAFaceAuthentificationEyes XSAAFaceAuthentificationEyes;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_EYES_DETECTOR (xsaa_face_authentification_eyes_detector_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_EYES_DETECTOR(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_EYES_DETECTOR, XSAAFaceAuthentificationEyesDetector))
#define XSAA_FACE_AUTHENTIFICATION_EYES_DETECTOR_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_EYES_DETECTOR, XSAAFaceAuthentificationEyesDetectorClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_EYES_DETECTOR(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_EYES_DETECTOR))
#define XSAA_FACE_AUTHENTIFICATION_IS_EYES_DETECTOR_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_EYES_DETECTOR))
#define XSAA_FACE_AUTHENTIFICATION_EYES_DETECTOR_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_EYES_DETECTOR, XSAAFaceAuthentificationEyesDetectorClass))

typedef struct _XSAAFaceAuthentificationEyesDetector XSAAFaceAuthentificationEyesDetector;
typedef struct _XSAAFaceAuthentificationEyesDetectorClass XSAAFaceAuthentificationEyesDetectorClass;
typedef struct _XSAAFaceAuthentificationEyesDetectorPrivate XSAAFaceAuthentificationEyesDetectorPrivate;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_FACE (xsaa_face_authentification_face_get_type ())
typedef struct _XSAAFaceAuthentificationFace XSAAFaceAuthentificationFace;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_DETECTOR (xsaa_face_authentification_face_detector_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_FACE_DETECTOR(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_DETECTOR, XSAAFaceAuthentificationFaceDetector))
#define XSAA_FACE_AUTHENTIFICATION_FACE_DETECTOR_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_DETECTOR, XSAAFaceAuthentificationFaceDetectorClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_FACE_DETECTOR(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_DETECTOR))
#define XSAA_FACE_AUTHENTIFICATION_IS_FACE_DETECTOR_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_DETECTOR))
#define XSAA_FACE_AUTHENTIFICATION_FACE_DETECTOR_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_DETECTOR, XSAAFaceAuthentificationFaceDetectorClass))

typedef struct _XSAAFaceAuthentificationFaceDetector XSAAFaceAuthentificationFaceDetector;
typedef struct _XSAAFaceAuthentificationFaceDetectorClass XSAAFaceAuthentificationFaceDetectorClass;
typedef struct _XSAAFaceAuthentificationFaceDetectorPrivate XSAAFaceAuthentificationFaceDetectorPrivate;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_DETECTOR (xsaa_face_authentification_detector_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_DETECTOR(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_DETECTOR, XSAAFaceAuthentificationDetector))
#define XSAA_FACE_AUTHENTIFICATION_DETECTOR_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_DETECTOR, XSAAFaceAuthentificationDetectorClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_DETECTOR(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_DETECTOR))
#define XSAA_FACE_AUTHENTIFICATION_IS_DETECTOR_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_DETECTOR))
#define XSAA_FACE_AUTHENTIFICATION_DETECTOR_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_DETECTOR, XSAAFaceAuthentificationDetectorClass))

typedef struct _XSAAFaceAuthentificationDetector XSAAFaceAuthentificationDetector;
typedef struct _XSAAFaceAuthentificationDetectorClass XSAAFaceAuthentificationDetectorClass;
typedef struct _XSAAFaceAuthentificationDetectorPrivate XSAAFaceAuthentificationDetectorPrivate;

#define XSAA_FACE_AUTHENTIFICATION_DETECTOR_TYPE_STATUS (xsaa_face_authentification_detector_status_get_type ())

#define XSAA_FACE_AUTHENTIFICATION_TYPE_VERIFY_STATUS (xsaa_face_authentification_verify_status_get_type ())

#define XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_IMAGES (xsaa_face_authentification_face_images_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_FACE_IMAGES(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_IMAGES, XSAAFaceAuthentificationFaceImages))
#define XSAA_FACE_AUTHENTIFICATION_FACE_IMAGES_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_IMAGES, XSAAFaceAuthentificationFaceImagesClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_FACE_IMAGES(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_IMAGES))
#define XSAA_FACE_AUTHENTIFICATION_IS_FACE_IMAGES_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_IMAGES))
#define XSAA_FACE_AUTHENTIFICATION_FACE_IMAGES_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_IMAGES, XSAAFaceAuthentificationFaceImagesClass))

typedef struct _XSAAFaceAuthentificationFaceImages XSAAFaceAuthentificationFaceImages;
typedef struct _XSAAFaceAuthentificationFaceImagesClass XSAAFaceAuthentificationFaceImagesClass;
typedef struct _XSAAFaceAuthentificationFaceImagesPrivate XSAAFaceAuthentificationFaceImagesPrivate;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_SET (xsaa_face_authentification_face_set_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_FACE_SET(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_SET, XSAAFaceAuthentificationFaceSet))
#define XSAA_FACE_AUTHENTIFICATION_FACE_SET_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_SET, XSAAFaceAuthentificationFaceSetClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_FACE_SET(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_SET))
#define XSAA_FACE_AUTHENTIFICATION_IS_FACE_SET_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_SET))
#define XSAA_FACE_AUTHENTIFICATION_FACE_SET_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_FACE_SET, XSAAFaceAuthentificationFaceSetClass))

typedef struct _XSAAFaceAuthentificationFaceSet XSAAFaceAuthentificationFaceSet;
typedef struct _XSAAFaceAuthentificationFaceSetClass XSAAFaceAuthentificationFaceSetClass;
typedef struct _XSAAFaceAuthentificationFaceSetPrivate XSAAFaceAuthentificationFaceSetPrivate;

#define XSAA_FACE_AUTHENTIFICATION_TYPE_VERIFIER (xsaa_face_authentification_verifier_get_type ())
#define XSAA_FACE_AUTHENTIFICATION_VERIFIER(obj) (G_TYPE_CHECK_INSTANCE_CAST ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_VERIFIER, XSAAFaceAuthentificationVerifier))
#define XSAA_FACE_AUTHENTIFICATION_VERIFIER_CLASS(klass) (G_TYPE_CHECK_CLASS_CAST ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_VERIFIER, XSAAFaceAuthentificationVerifierClass))
#define XSAA_FACE_AUTHENTIFICATION_IS_VERIFIER(obj) (G_TYPE_CHECK_INSTANCE_TYPE ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_VERIFIER))
#define XSAA_FACE_AUTHENTIFICATION_IS_VERIFIER_CLASS(klass) (G_TYPE_CHECK_CLASS_TYPE ((klass), XSAA_FACE_AUTHENTIFICATION_TYPE_VERIFIER))
#define XSAA_FACE_AUTHENTIFICATION_VERIFIER_GET_CLASS(obj) (G_TYPE_INSTANCE_GET_CLASS ((obj), XSAA_FACE_AUTHENTIFICATION_TYPE_VERIFIER, XSAAFaceAuthentificationVerifierClass))

typedef struct _XSAAFaceAuthentificationVerifier XSAAFaceAuthentificationVerifier;
typedef struct _XSAAFaceAuthentificationVerifierClass XSAAFaceAuthentificationVerifierClass;
typedef struct _XSAAFaceAuthentificationVerifierPrivate XSAAFaceAuthentificationVerifierPrivate;

typedef enum  {
	XSAA_FACE_AUTHENTIFICATION_STATUS_STOPPED = 28,
	XSAA_FACE_AUTHENTIFICATION_STATUS_STARTED = 21
} XSAAFaceAuthentificationStatus;

typedef enum  {
	XSAA_FACE_AUTHENTIFICATION_MACE_DEFAULT_FACE = 24,
	XSAA_FACE_AUTHENTIFICATION_MACE_DEFAULT_EYE = 25,
	XSAA_FACE_AUTHENTIFICATION_MACE_DEFAULT_INSIDE_FACE = 26
} XSAAFaceAuthentificationMaceDefault;

struct _XSAAFaceAuthentificationWebcam {
	GObject parent_instance;
	XSAAFaceAuthentificationWebcamPrivate * priv;
};

struct _XSAAFaceAuthentificationWebcamClass {
	GObjectClass parent_class;
};

struct _XSAAFaceAuthentificationTracker {
	GObject parent_instance;
	XSAAFaceAuthentificationTrackerPrivate * priv;
};

struct _XSAAFaceAuthentificationTrackerClass {
	GObjectClass parent_class;
};

struct _XSAAFaceAuthentificationEyes {
	CvPoint le;
	CvPoint re;
	gint length;
};

struct _XSAAFaceAuthentificationEyesDetector {
	GObject parent_instance;
	XSAAFaceAuthentificationEyesDetectorPrivate * priv;
};

struct _XSAAFaceAuthentificationEyesDetectorClass {
	GObjectClass parent_class;
};

struct _XSAAFaceAuthentificationFace {
	CvPoint lt;
	CvPoint rb;
	gint width;
	gint height;
};

struct _XSAAFaceAuthentificationFaceDetector {
	GObject parent_instance;
	XSAAFaceAuthentificationFaceDetectorPrivate * priv;
};

struct _XSAAFaceAuthentificationFaceDetectorClass {
	GObjectClass parent_class;
};

struct _XSAAFaceAuthentificationDetector {
	GObject parent_instance;
	XSAAFaceAuthentificationDetectorPrivate * priv;
};

struct _XSAAFaceAuthentificationDetectorClass {
	GObjectClass parent_class;
};

typedef enum  {
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_INVALID = -1,
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_TO_FAR,
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_TO_CLOSER,
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_UNABLE_TO_DETECT,
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_LOST_TRACKER,
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_TRACKING,
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_CAPTURE,
	XSAA_FACE_AUTHENTIFICATION_DETECTOR_STATUS_FINISHED
} XSAAFaceAuthentificationDetectorStatus;

typedef enum  {
	XSAA_FACE_AUTHENTIFICATION_VERIFY_STATUS_IMPOSTER,
	XSAA_FACE_AUTHENTIFICATION_VERIFY_STATUS_OK,
	XSAA_FACE_AUTHENTIFICATION_VERIFY_STATUS_NO_BIOMETRICS
} XSAAFaceAuthentificationVerifyStatus;

struct _XSAAFaceAuthentificationFaceImages {
	GTypeInstance parent_instance;
	volatile int ref_count;
	XSAAFaceAuthentificationFaceImagesPrivate * priv;
	IplImage** faces;
	gint faces_length1;
};

struct _XSAAFaceAuthentificationFaceImagesClass {
	GTypeClass parent_class;
	void (*finalize) (XSAAFaceAuthentificationFaceImages *self);
};

struct _XSAAFaceAuthentificationFaceSet {
	GTypeInstance parent_instance;
	volatile int ref_count;
	XSAAFaceAuthentificationFaceSetPrivate * priv;
	gchar** name;
	gint name_length1;
	XSAAFaceAuthentificationFaceImages** face_images;
	gint face_images_length1;
	gchar** thumbnails;
	gint thumbnails_length1;
	gint count;
};

struct _XSAAFaceAuthentificationFaceSetClass {
	GTypeClass parent_class;
	void (*finalize) (XSAAFaceAuthentificationFaceSet *self);
};

struct _XSAAFaceAuthentificationVerifier {
	GObject parent_instance;
	XSAAFaceAuthentificationVerifierPrivate * priv;
};

struct _XSAAFaceAuthentificationVerifierClass {
	GObjectClass parent_class;
};


GType xsaa_face_authentification_status_get_type (void) G_GNUC_CONST;
#define XSAA_FACE_AUTHENTIFICATION_IPC_KEY_IMAGE ((key_t) 567814)
#define XSAA_FACE_AUTHENTIFICATION_IPC_KEY_STATUS ((key_t) 567813)
#define XSAA_FACE_AUTHENTIFICATION_IMAGE_WIDTH 320
#define XSAA_FACE_AUTHENTIFICATION_IMAGE_HEIGHT 240
#define XSAA_FACE_AUTHENTIFICATION_IMAGE_SIZE 307200
GType xsaa_face_authentification_mace_default_get_type (void) G_GNUC_CONST;
#define XSAA_FACE_AUTHENTIFICATION_USER_CONFIG_PATH "/.config/xsplashaa/face-authentification"
gboolean xsaa_face_authentification_check_bit (gint inI);
gdouble xsaa_face_authentification_get_bit (IplImage* inImage, gdouble inPx, gdouble inPy, gdouble inThreshold);
void xsaa_face_authentification_feature_lbp_hist (IplImage* inImage, CvMat* inFeaturesFinal);
gdouble xsaa_face_authentification_lbp_custom_diff (CvMat* inModel, CvMat* inTest, CvMat* inWeight);
void xsaa_face_authentification_shift_dft (CvArr* inSrcArr, CvArr* inDstArr);
gint xsaa_face_authentification_peak_to_side_lobe_ratio (CvMat* inMaceFilterVisualize, IplImage* inImage, gint inSizeOfImage);
gdouble xsaa_face_authentification_center_of_mass (IplImage* inSrc, gboolean inFlagXY);
void xsaa_face_authentification_rotate (gdouble inAngle, gfloat inCentreX, gfloat inCentreY, IplImage* inImg, IplImage* inDstImg);
GType xsaa_face_authentification_webcam_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationWebcam* xsaa_face_authentification_webcam_new (gint inCameraIndex);
XSAAFaceAuthentificationWebcam* xsaa_face_authentification_webcam_construct (GType object_type, gint inCameraIndex);
gboolean xsaa_face_authentification_webcam_start (XSAAFaceAuthentificationWebcam* self);
void xsaa_face_authentification_webcam_stop (XSAAFaceAuthentificationWebcam* self);
IplImage* xsaa_face_authentification_webcam_query_frame (XSAAFaceAuthentificationWebcam* self);
GType xsaa_face_authentification_tracker_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationTracker* xsaa_face_authentification_tracker_new (void);
XSAAFaceAuthentificationTracker* xsaa_face_authentification_tracker_construct (GType object_type);
void xsaa_face_authentification_tracker_track_image (XSAAFaceAuthentificationTracker* self, IplImage* inInput);
void xsaa_face_authentification_tracker_find_point (XSAAFaceAuthentificationTracker* self, CvPoint inP1, CvPoint* outP2);
void xsaa_face_authentification_tracker_set_model (XSAAFaceAuthentificationTracker* self, IplImage* inInput);
gdouble xsaa_face_authentification_tracker_get_last_difference_1 (XSAAFaceAuthentificationTracker* self);
void xsaa_face_authentification_tracker_set_last_difference_1 (XSAAFaceAuthentificationTracker* self, gdouble value);
gdouble xsaa_face_authentification_tracker_get_last_difference_2 (XSAAFaceAuthentificationTracker* self);
void xsaa_face_authentification_tracker_set_last_difference_2 (XSAAFaceAuthentificationTracker* self, gdouble value);
CvPoint xsaa_face_authentification_tracker_get_anchor_point (XSAAFaceAuthentificationTracker* self);
void xsaa_face_authentification_tracker_set_anchor_point (XSAAFaceAuthentificationTracker* self, CvPoint value);
GType xsaa_face_authentification_eyes_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationEyes* xsaa_face_authentification_eyes_dup (const XSAAFaceAuthentificationEyes* self);
void xsaa_face_authentification_eyes_free (XSAAFaceAuthentificationEyes* self);
GType xsaa_face_authentification_eyes_detector_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationEyesDetector* xsaa_face_authentification_eyes_detector_new (void);
XSAAFaceAuthentificationEyesDetector* xsaa_face_authentification_eyes_detector_construct (GType object_type);
void xsaa_face_authentification_eyes_detector_run (XSAAFaceAuthentificationEyesDetector* self, IplImage* inInput, IplImage* inFullImage, CvPoint inLT);
void xsaa_face_authentification_eyes_detector_get_eyes_information (XSAAFaceAuthentificationEyesDetector* self, XSAAFaceAuthentificationEyes* result);
gboolean xsaa_face_authentification_eyes_detector_get_eyes_detected (XSAAFaceAuthentificationEyesDetector* self);
GType xsaa_face_authentification_face_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationFace* xsaa_face_authentification_face_dup (const XSAAFaceAuthentificationFace* self);
void xsaa_face_authentification_face_free (XSAAFaceAuthentificationFace* self);
GType xsaa_face_authentification_face_detector_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationFaceDetector* xsaa_face_authentification_face_detector_new (void);
XSAAFaceAuthentificationFaceDetector* xsaa_face_authentification_face_detector_construct (GType object_type);
void xsaa_face_authentification_face_detector_run (XSAAFaceAuthentificationFaceDetector* self, IplImage* inInput);
IplImage* xsaa_face_authentification_face_detector_clip_detected_face (XSAAFaceAuthentificationFaceDetector* self, IplImage* inInput);
void xsaa_face_authentification_face_detector_get_face_information (XSAAFaceAuthentificationFaceDetector* self, XSAAFaceAuthentificationFace* result);
gboolean xsaa_face_authentification_face_detector_get_face_detected (XSAAFaceAuthentificationFaceDetector* self);
GType xsaa_face_authentification_detector_get_type (void) G_GNUC_CONST;
GType xsaa_face_authentification_detector_status_get_type (void) G_GNUC_CONST;
gchar* xsaa_face_authentification_detector_status_to_string (XSAAFaceAuthentificationDetectorStatus self);
XSAAFaceAuthentificationDetector* xsaa_face_authentification_detector_new (void);
XSAAFaceAuthentificationDetector* xsaa_face_authentification_detector_construct (GType object_type);
IplImage* xsaa_face_authentification_detector_clip_face (XSAAFaceAuthentificationDetector* self, IplImage* inInputImage);
void xsaa_face_authentification_detector_run (XSAAFaceAuthentificationDetector* self, IplImage* inInput);
XSAAFaceAuthentificationDetectorStatus xsaa_face_authentification_detector_get_status (XSAAFaceAuthentificationDetector* self);
void xsaa_face_authentification_detector_set_status (XSAAFaceAuthentificationDetector* self, XSAAFaceAuthentificationDetectorStatus value);
gboolean xsaa_face_authentification_detector_get_detected (XSAAFaceAuthentificationDetector* self);
GType xsaa_face_authentification_verify_status_get_type (void) G_GNUC_CONST;
gpointer xsaa_face_authentification_face_images_ref (gpointer instance);
void xsaa_face_authentification_face_images_unref (gpointer instance);
GParamSpec* xsaa_face_authentification_param_spec_face_images (const gchar* name, const gchar* nick, const gchar* blurb, GType object_type, GParamFlags flags);
void xsaa_face_authentification_value_set_face_images (GValue* value, gpointer v_object);
void xsaa_face_authentification_value_take_face_images (GValue* value, gpointer v_object);
gpointer xsaa_face_authentification_value_get_face_images (const GValue* value);
GType xsaa_face_authentification_face_images_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationFaceImages* xsaa_face_authentification_face_images_new (void);
XSAAFaceAuthentificationFaceImages* xsaa_face_authentification_face_images_construct (GType object_type);
gpointer xsaa_face_authentification_face_set_ref (gpointer instance);
void xsaa_face_authentification_face_set_unref (gpointer instance);
GParamSpec* xsaa_face_authentification_param_spec_face_set (const gchar* name, const gchar* nick, const gchar* blurb, GType object_type, GParamFlags flags);
void xsaa_face_authentification_value_set_face_set (GValue* value, gpointer v_object);
void xsaa_face_authentification_value_take_face_set (GValue* value, gpointer v_object);
gpointer xsaa_face_authentification_value_get_face_set (const GValue* value);
GType xsaa_face_authentification_face_set_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationFaceSet* xsaa_face_authentification_face_set_new (void);
XSAAFaceAuthentificationFaceSet* xsaa_face_authentification_face_set_construct (GType object_type);
GType xsaa_face_authentification_verifier_get_type (void) G_GNUC_CONST;
XSAAFaceAuthentificationVerifier* xsaa_face_authentification_verifier_new (void);
XSAAFaceAuthentificationVerifier* xsaa_face_authentification_verifier_construct (GType object_type);
XSAAFaceAuthentificationVerifier* xsaa_face_authentification_verifier_new_uid (uid_t inUid);
XSAAFaceAuthentificationVerifier* xsaa_face_authentification_verifier_construct_uid (GType object_type, uid_t inUid);
XSAAFaceAuthentificationFaceSet* xsaa_face_authentification_verifier_get_face_set (XSAAFaceAuthentificationVerifier* self);
void xsaa_face_authentification_verifier_create_biometric_models (XSAAFaceAuthentificationVerifier* self, const gchar* inSetName);
void xsaa_face_authentification_verifier_add_face_set (XSAAFaceAuthentificationVerifier* self, IplImage** inSet, int inSet_length1);
void xsaa_face_authentification_verifier_remove_face_set (XSAAFaceAuthentificationVerifier* self, const gchar* inSetName);
XSAAFaceAuthentificationVerifyStatus xsaa_face_authentification_verifier_verify_face (XSAAFaceAuthentificationVerifier* self, IplImage* inFace);
const gchar* xsaa_face_authentification_verifier_get_faces_directory (XSAAFaceAuthentificationVerifier* self);
const gchar* xsaa_face_authentification_verifier_get_model_directory (XSAAFaceAuthentificationVerifier* self);
const gchar* xsaa_face_authentification_verifier_get_config_directory (XSAAFaceAuthentificationVerifier* self);


G_END_DECLS

#endif
