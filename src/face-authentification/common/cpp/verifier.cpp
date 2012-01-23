/*
    Verifier class
    Copyright (C) 2010 Rohan Anil (rohan.anil@gmail.com) -BITS Pilani Goa Campus
    http://www.pam-face-authentication.org

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, version 3 of the License.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

#include <iostream>
#include <list>
#include <string>
#include <cctype>
#include <cstdio>

#include <dirent.h>
#include <pwd.h> /* getpwdid */
#include <sys/stat.h>
#include <sys/time.h>
#include <sys/types.h>
#include <unistd.h>
#include "cv.h"
#include "pam_face_defines.h"
#include "utils.h"
#include "verifier.h"

#define FACE_MACE_SIZE 64
#define EYE_MACE_SIZE 64
#define INSIDE_FACE_MACE_SIZE 64

using std::string;
using std::list;

//------------------------------------------------------------------------------
verifier::verifier()
{
    uid_t userID = getuid();
    userStruct = getpwuid(getuid());
    string basePath = string(userStruct->pw_dir); // Current user homedir
    string maceConfig = "";

    basePath.append(PFA_PATH); // homedir + /.pam_face_authentication
    facesDirectory = basePath  + "/faces";
    modelDirectory = basePath + "/model";
    configDirectory = basePath + "/config";
    maceConfig = configDirectory + "/mace.xml";

    // Create the paths
    mkdir(basePath.c_str(), S_IRWXU);
    mkdir(facesDirectory.c_str(), S_IRWXU);
    mkdir(modelDirectory.c_str(), S_IRWXU);
    mkdir(configDirectory.c_str(), S_IRWXU);

    // If there is no config file existing, create a new configuration
    FILE* fp = fopen(maceConfig.c_str(), "r");
    if(fp) fclose(fp);
    else
    {
        // Default config
        config newConfig;
        newConfig.percentage = .80;
        setConfig(&newConfig, (char*)configDirectory.c_str());
    }

}

//------------------------------------------------------------------------------
verifier::verifier(uid_t userID)
{
    userStruct = getpwuid(userID);
    string basePath = string(userStruct->pw_dir); // Current user homedir
    string maceConfig = "";

    basePath.append(PFA_PATH); // homedir + /.pam_face_authentication
    facesDirectory = basePath  + "/faces";
    modelDirectory = basePath + "/model";
    configDirectory = basePath + "/config";
    maceConfig = configDirectory + "/mace.xml";
}

//------------------------------------------------------------------------------
verifier::~verifier()
{
}

//------------------------------------------------------------------------------
void verifier::createBiometricModels(char* setName = NULL)
{
    //cvNamedWindow("eyeRight", 1);

    setFace* temp = getFaceSet();
    int leftIndex = 0;
    int rightIndex = temp->count;

    if(setName != NULL)
    {
        for(int i = 0; i < temp->count; i++)
        {
            if(strcmp(temp->setName[i], setName) == 0)
            {
                leftIndex = i;
                rightIndex = leftIndex+1;
            }

        }
    }

    for(int i = leftIndex; i < rightIndex; i++)
    {
        int avFace = 0, avEye = 0, avInsideFace = 0;

        list<int>* maceFaceValuesPSLR = new list<int>;
        list<double>* maceFaceValuesPCER = new list<double>;
        list<int>* maceEyeValuesPSLR = new list<int>;
        list<double>* maceEyeValuesPCER = new list<double>;
        list<int>* maceInsideFaceValuesPSLR = new list<int>;
        list<double>* maceInsideFaceValuesPCER = new list<double>;
        list<double>* lbpAv = new list<double>;

        IplImage** eye = new IplImage* [temp->faceImages[i].count];
        IplImage** insideFace = new IplImage* [temp->faceImages[i].count];

        for(int index = 0; index < temp->faceImages[i].count; index++)
        {
            eye[index] = cvCreateImage(
                cvSize(EYE_MACE_SIZE, EYE_MACE_SIZE), 8,
                temp->faceImages[i].faces[index]->nChannels);
            cvSetImageROI(temp->faceImages[i].faces[index], cvRect(0, 0, 140, 60));
            cvResize(temp->faceImages[i].faces[index], eye[index], CV_INTER_LINEAR);
            cvResetImageROI(temp->faceImages[i].faces[index]);

            insideFace[index] = cvCreateImage(
                cvSize(INSIDE_FACE_MACE_SIZE, INSIDE_FACE_MACE_SIZE), 8,
                temp->faceImages[i].faces[index]->nChannels);
            cvSetImageROI(temp->faceImages[i].faces[index], cvRect(30, 45, 80, 105));
            cvResize(temp->faceImages[i].faces[index], insideFace[index], CV_INTER_LINEAR);
            cvResetImageROI(temp->faceImages[i].faces[index]);
        }

        CvMat* maceFilterFace = computeMace(temp->faceImages[i].faces,
            temp->faceImages[i].count, FACE_MACE_SIZE);

        CvMat* maceFilterEye = computeMace(eye,
            temp->faceImages[i].count, EYE_MACE_SIZE);

        CvMat* maceFilterInsideFace = computeMace(insideFace,
            temp->faceImages[i].count, INSIDE_FACE_MACE_SIZE);

        IplImage* averageImage = cvCreateImage(
            // cvSize(temp->faceImages[i].faces[0]->width, temp->faceImages[i].faces[0]->height),
            cvGetSize(temp->faceImages[i].faces[0]), IPL_DEPTH_64F, 1);
        cvZero(averageImage);

        for(int index = 0; index < temp->faceImages[i].count; index++)
        {
            IplImage* averageImageFace = cvCreateImage(
                //cvSize(temp->faceImages[i].faces[index]->width, temp->faceImages[i].faces[index]->height),
                cvGetSize(temp->faceImages[i].faces[index]), IPL_DEPTH_64F, 1);
            IplImage* averageImageFace64 = cvCreateImage(
                //cvSize(temp->faceImages[i].faces[index]->width,temp->faceImages[i].faces[index]->height),
                cvGetSize(temp->faceImages[i].faces[index]), 8, 1);
            cvCvtColor(temp->faceImages[i].faces[index], averageImageFace64, CV_BGR2GRAY);
            cvScale(averageImageFace64, averageImageFace, 1.0, 0.0);
            cvAdd(averageImage, averageImageFace, averageImage);
            cvReleaseImage(&averageImageFace);
            cvReleaseImage(&averageImageFace64);

            double macePCERValue = peakCorrPlaneEnergy(
                maceFilterFace, temp->faceImages[i].faces[index], FACE_MACE_SIZE);
            int macePSLRValue = peakToSideLobeRatio(
                maceFilterFace, temp->faceImages[i].faces[index], FACE_MACE_SIZE);
            avFace += macePSLRValue;
            maceFaceValuesPSLR->push_back(macePSLRValue);
            maceFaceValuesPCER->push_back(macePCERValue);

            macePCERValue = peakCorrPlaneEnergy(
                maceFilterEye,eye[index], EYE_MACE_SIZE);
            macePSLRValue = peakToSideLobeRatio(
                maceFilterEye,eye[index], EYE_MACE_SIZE);
            avEye += macePSLRValue;
            maceEyeValuesPSLR->push_back(macePSLRValue);
            maceEyeValuesPCER->push_back(macePCERValue);

            macePCERValue = peakCorrPlaneEnergy(
                maceFilterInsideFace, insideFace[index], INSIDE_FACE_MACE_SIZE);
            macePSLRValue = peakToSideLobeRatio(
                maceFilterInsideFace, insideFace[index], INSIDE_FACE_MACE_SIZE);
            avInsideFace += macePSLRValue;
            maceInsideFaceValuesPSLR->push_back(macePSLRValue);
            maceInsideFaceValuesPCER->push_back(macePCERValue);
        }

        avFace /= temp->faceImages[i].count;
        avEye /= temp->faceImages[i].count;
        avInsideFace /= temp->faceImages[i].count;

        int Nx = floor((averageImage->width )/35);
        int Ny = floor((averageImage->height)/30);
        // printf("%d %d A \n",Nx,Ny);
        CvMat* featureLBPHistMatrix = cvCreateMat(Nx*Ny*59, 1, CV_64FC1);
        featureLBPHist(averageImage, featureLBPHistMatrix);
        IplImage* weights = cvCreateImage(cvSize(5*4, temp->faceImages[i].count),
            IPL_DEPTH_64F, 1);

        for(int index = 0; index < temp->faceImages[i].count; index++)
        {
            IplImage* averageImageFace = cvCreateImage(
                //cvSize(temp->faceImages[i].faces[index]->width,temp->faceImages[i].faces[index]->height),
                cvGetSize(temp->faceImages[i].faces[index]), IPL_DEPTH_64F, 1);
            IplImage* averageImageFace64 = cvCreateImage(
                //cvSize(temp->faceImages[i].faces[index]->width,temp->faceImages[i].faces[index]->height);
                cvGetSize(temp->faceImages[i].faces[index]), 8, 1);
            cvCvtColor(temp->faceImages[i].faces[index], averageImageFace64, CV_BGR2GRAY);
            cvScale(averageImageFace64, averageImageFace, 1.0, 0.0);
            CvMat* featureLBPHistMatrixFace = cvCreateMat(Nx*Ny*59,1, CV_64FC1);
            featureLBPHist(averageImageFace, featureLBPHistMatrixFace);

            for(int i = 0; i < 5; i++)
            {
                for(int j = 0; j < 4; j++)
                {
                    double chiSquare = 0;

                    for(int k = 0; k < 59; k++)
                    {
                        CvScalar s1 = cvGet2D(featureLBPHistMatrixFace, i*4*59 + j*59 +k, 0);
                        CvScalar s2 = cvGet2D(featureLBPHistMatrix, i*4*59 + j*59 +k, 0);

                        double hist1 = s1.val[0];
                        double hist2 = s2.val[0];

                        if((hist1 + hist2) != 0)
                            chiSquare += (pow(hist1 - hist2, 2) / (hist1 + hist2));

                        // printf("%e \n", weights[i][j]);
                    }
                    CvScalar s1;
                    s1.val[0] = chiSquare;
                    cvSet2D(weights, index, j*5 + i, s1);
                }
            }

            cvReleaseMat(&featureLBPHistMatrixFace);
            cvReleaseImage(&averageImageFace);
            cvReleaseImage(&averageImageFace64);
        }

        IplImage* variance = cvCreateImage( cvSize(5*4, 1), IPL_DEPTH_64F, 1);
        IplImage* sum = cvCreateImage( cvSize(5*4,1), IPL_DEPTH_64F, 1);
        IplImage* sumSq = cvCreateImage( cvSize(5*4,1), IPL_DEPTH_64F, 1);
        IplImage* meanSq = cvCreateImage( cvSize(5*4,1), IPL_DEPTH_64F, 1);
        cvZero(variance);
        cvZero(sum);
        cvZero(sumSq);

        for(int index = 0; index < temp->faceImages[i].count; index++)
        {
            for(int i = 0; i < 5; i++)
            {
                for(int j = 0; j < 4; j++)
                {
                    CvScalar s1, s2, s3, s4;

                    s1= cvGet2D(weights,index,j*5 + i);
                    s2= cvGet2D(sum,0,j*5 + i);
                    s3.val[0] = s1.val[0] + s2.val[0];
                    s4= cvGet2D(sumSq,0,j*5 + i);

                    cvSet2D(sum, 0, j*5 + i, s3);
                    s1.val[0] *= s1.val[0];
                    s1.val[0] += s4.val[0];
                    cvSet2D(sumSq, 0, j*5 + i, s1);
                }
            }
        }

        cvConvertScale(sum, sum, 1 / (double)temp->faceImages[i].count);
        cvConvertScale(sumSq, sumSq, 1 / (double)temp->faceImages[i].count);
        cvMul(sum, sum, meanSq);
        cvSub(sumSq, meanSq, variance);

        for(int j = 0; j < 4; j++)
        {
            for(int i = 0; i < 5; i++)
            {
                CvScalar s1 = cvGet2D(variance, 0, j*5 + i);
                // printf("%e\t", s1.val[0]);
            }
            // printf("\n");
        }
        // printf("\n");

        cvDiv(NULL, variance, variance);
        CvScalar totalVariance = cvSum(variance);
        CvMat* finalWeights = cvCreateMat(4, 5, CV_64FC1);
        for(int j = 0; j < 4; j++)
        {
            for(int i = 0; i < 5; i++)
            {
                CvScalar s1 = cvGet2D(variance, 0, j*5 + i);
                s1.val[0]= (s1.val[0]*20) / totalVariance.val[0];
                cvSet2D(finalWeights, j, i, s1);
            }
            // printf("\n");
        }
        //  printf("\n");

        cvReleaseImage(&variance);
        cvReleaseImage(&sumSq);
        cvReleaseImage(&meanSq);
        cvReleaseImage(&sum);

        char lbpFacePath[300];
        sprintf(lbpFacePath, "%s/%s_face_lbp.xml", modelDirectory.c_str(), temp->setName[i]);
        CvFileStorage* fs = cvOpenFileStorage(lbpFacePath, 0, CV_STORAGE_WRITE);
        cvWrite(fs, "lbp", featureLBPHistMatrix, cvAttrList(0,0) );
        cvWrite(fs, "weights", finalWeights, cvAttrList(0,0) );

        for(int index = 0; index < temp->faceImages[i].count; index++)
        {
            CvMat* featureLBPHistMatrixTest = cvCreateMat(Nx*Ny*59, 1, CV_64FC1);
            IplImage* imageFace = cvCreateImage(
                //cvSize(temp->faceImages[i].faces[index]->width, temp->faceImages[i].faces[index]->height)
                cvGetSize(temp->faceImages[i].faces[index]), 8, 1);
            cvCvtColor(temp->faceImages[i].faces[index], imageFace, CV_BGR2GRAY);
            featureLBPHist(imageFace, featureLBPHistMatrixTest);
            lbpAv->push_back(LBPCustomDiff(featureLBPHistMatrixTest, featureLBPHistMatrix, finalWeights));
            cvReleaseMat(&featureLBPHistMatrixTest);
            cvReleaseImage(&imageFace);
        }

        cvReleaseMat(&finalWeights);
        cvReleaseMat(&featureLBPHistMatrix);
        lbpAv->sort();

        int half = (temp->faceImages[i].count/2) - 1;
        if(half > 0)
        {
            while(half >= 0)
            {
                lbpAv->pop_front();
                half--;
            }
        }
        cvWriteReal(fs, "thresholdLbp", lbpAv->front());
        cvReleaseFileStorage(&fs);

        cvReleaseImage(&averageImage);
        maceFaceValuesPSLR->sort();
        maceFaceValuesPCER->sort();
        maceEyeValuesPSLR->sort();
        maceEyeValuesPCER->sort();
        maceInsideFaceValuesPSLR->sort();
        maceInsideFaceValuesPCER->sort();

        mace faceMaceFilter, eyeMaceFilter, insideFaceMaceFilter;

        faceMaceFilter.thresholdPCER = maceFaceValuesPCER->front();
        faceMaceFilter.thresholdPSLR = maceFaceValuesPSLR->front()
            + (avFace-maceFaceValuesPSLR->front()) / 10;
        // printf("%d %d \n", maceFaceValuesPSLR->front(), avFace);
        faceMaceFilter.filter = maceFilterFace;
        sprintf(faceMaceFilter.maceFilterName, "%s_face_mace.xml", temp->setName[i]);

        eyeMaceFilter.thresholdPCER = maceEyeValuesPCER->front();
        eyeMaceFilter.thresholdPSLR = maceEyeValuesPSLR->front()
            + (avEye-maceEyeValuesPSLR->front()) / 10;
        eyeMaceFilter.filter = maceFilterEye;
        sprintf(eyeMaceFilter.maceFilterName, "%s_eye_mace.xml", temp->setName[i]);
        // printf("%d %d \n",maceEyeValuesPSLR->front(), avEye);

        insideFaceMaceFilter.thresholdPCER = maceInsideFaceValuesPCER->front();
        insideFaceMaceFilter.thresholdPSLR = maceInsideFaceValuesPSLR->front()
            + (avInsideFace-maceInsideFaceValuesPSLR->front()) / 10;
        insideFaceMaceFilter.filter = maceFilterInsideFace;

        sprintf(insideFaceMaceFilter.maceFilterName,"%s_inside_face_mace.xml",temp->setName[i]);
        //printf("%d %d \n",maceInsideFaceValuesPSLR->front(),avInsideFace);

        saveMace(&faceMaceFilter, modelDirectory.c_str());
        saveMace(&eyeMaceFilter, modelDirectory.c_str());
        saveMace(&insideFaceMaceFilter, modelDirectory.c_str());

        for(int index = 0; index < temp->faceImages[i].count; index++)
        {
            cvReleaseImage(&eye[index]);
            cvReleaseImage(&insideFace[index]);
        }

        delete[] eye;
        delete[] insideFace;

    }

    delete temp;

}

//------------------------------------------------------------------------------
string verifier::createSetDir() const
{
    time_t ltime = time(NULL);
    char setDir[256];
    char uniqueName[256];
    struct tm *Tm;
    struct timeval detail_time;

    Tm = localtime(&ltime);
    gettimeofday(&detail_time, NULL);
    sprintf(uniqueName, "%d%d%d%d%d%d%ld%ld%d", Tm->tm_year, Tm->tm_mon,
            Tm->tm_mday, Tm->tm_hour, Tm->tm_min, Tm->tm_sec,
            (detail_time.tv_usec/1000), detail_time.tv_usec, Tm->tm_wday);
    sprintf(setDir, "%s/.pam-face-authentication/faces/%s",
            userStruct->pw_dir,uniqueName);
    mkdir(setDir, S_IRWXU );

    return string(uniqueName);
}

//------------------------------------------------------------------------------
void verifier::addFaceSet(IplImage** set, int size)
{
    string dirNameUnique = createSetDir();
    string dirName = facesDirectory;
    char filename[300];

    dirName += "/" + dirNameUnique;

    for (int i = 0; i < size; i++)
    {
        sprintf(filename, "%s/%d.jpg", dirName.c_str(), i);
        cvSaveImage(filename, set[i]);
        cvReleaseImage(&set[i]);
    }

    createBiometricModels((char*)dirNameUnique.c_str());
    delete[] set;
}

//------------------------------------------------------------------------------
void verifier::removeFaceSet(char* setName)
{
    char dirname[300], filename[300], maceFilters[300];
    struct dirent* de = NULL;
    sprintf(dirname, "%s/%s", facesDirectory.c_str(), setName);

    DIR* d=opendir(dirname);
    while (de = readdir(d))
    {
        if (strcmp(de->d_name + strlen(de->d_name)-3, "jpg") == 0)
        {
            sprintf(filename, "%s/%s", dirname, de->d_name);
            // printf("%s\n", filename);
            remove(filename);
        }
    }

    sprintf(maceFilters,"%s/%s_face_lbp.xml", modelDirectory.c_str(), setName);
    remove(maceFilters);
    sprintf(maceFilters,"%s/%s_face_mace.xml", modelDirectory.c_str(), setName);
    remove(maceFilters);
    sprintf(maceFilters,"%s/%s_eye_mace.xml", modelDirectory.c_str(), setName);
    remove(maceFilters);
    sprintf(maceFilters,"%s/%s_inside_face_mace.xml", modelDirectory.c_str(), setName);
    remove(maceFilters);
    remove(dirname);

    // createBiometricModels();
    // sprintf(dirname, "%s/%s_mace.xml", modelDirectory, setName);
    // remove(dirname);
}

//------------------------------------------------------------------------------
int verifier::verifyFace(IplImage* faceMain)
{
    struct dirent *de = NULL;
    DIR* d = NULL;
    int count = 0, k = 0;

    if (faceMain == 0) return 0;

    list<string>* faceSetName = new list<string>;
    list<string>::iterator it;

    CvFileStorage* fileStorage;
    CvMat* maceFilterUser;
    CvMat* lbpModel;
    CvMat* weights;

    IplImage* face = cvCreateImage(cvSize(140, 150), 8, faceMain->nChannels);
    IplImage* faceGray = cvCreateImage(cvSize(140, 150), 8, 1);
    int Nx = floor((faceGray->width )/35);
    int Ny= floor((faceGray->height)/30);

    CvMat* featureLBPHistMatrix = cvCreateMat(Nx*Ny*59, 1, CV_64FC1);

    cvResize(faceMain, face, CV_INTER_LINEAR);
    cvCvtColor(face, faceGray, CV_BGR2GRAY);
    featureLBPHist(faceGray, featureLBPHistMatrix);

    IplImage* eye = cvCreateImage(cvSize(140, 60), 8, face->nChannels);
    cvSetImageROI(face, cvRect(0, 0, 140, 60));
    cvResize(face, eye, CV_INTER_LINEAR );
    cvResetImageROI(face);

    IplImage* insideFace = cvCreateImage(cvSize(80, 105), 8, face->nChannels);
    cvSetImageROI(face, cvRect(30, 45, 80, 105));
    cvResize(face, insideFace, CV_INTER_LINEAR);
    cvResetImageROI(face);

    config* newConfig = getConfig((char*)configDirectory.c_str());

    d = opendir(facesDirectory.c_str());
    if (!d) return 2;

    while (de = readdir(d))
    {
        if (!((strcmp(de->d_name, ".") == 0) || (strcmp(de->d_name, "..") == 0)))
        {
            //  printf("%s -- \n",de->d_name);
            k++;
            char facePath[300];
            char eyePath[300];
            char insideFacePath[300];
            char lbp[300];

            sprintf(lbp, "%s/%s_face_lbp.xml", modelDirectory.c_str(), de->d_name);
            fileStorage = cvOpenFileStorage(lbp, 0, CV_STORAGE_READ );
            if (fileStorage == 0) continue;

            lbpModel = (CvMat *)cvReadByName(fileStorage, 0, "lbp", 0);
            weights = (CvMat *)cvReadByName(fileStorage, 0, "weights", 0);
            if (lbpModel == 0) continue;
            if (weights == 0) continue;

            double lbpThresh = cvReadRealByName(fileStorage, 0, "thresholdLbp",8000);
            double val = LBPCustomDiff(lbpModel, featureLBPHistMatrix,weights);
            cvReleaseMat(&lbpModel);
            double step =lbpThresh/8;

            // double thresholdLBP = MAX_THRESHOLD_LBP-(newConfig->percentage*10000);
            double thresholdLBP = lbpThresh;
            double percentageModifier =((.80-newConfig->percentage)*100);
            int baseIncrease =floor(log10(lbpThresh)) - 2;
            while (baseIncrease>0)
            {
                percentageModifier*=10;
                baseIncrease--;
            }
            thresholdLBP+=percentageModifier*1.2;
            //printf("%e %e %e\n", val, (thresholdLBP+step), step);

            if (val < (thresholdLBP+step))
            {
                //printf("\ntrue\n");
                sprintf(facePath, "%s/%s_face_mace.xml", modelDirectory.c_str(), de->d_name);
                sprintf(eyePath, "%s/%s_eye_mace.xml", modelDirectory.c_str(), de->d_name);
                sprintf(insideFacePath, "%s/%s_inside_face_mace.xml", modelDirectory.c_str(),
                        de->d_name);

                fileStorage = cvOpenFileStorage(facePath, 0, CV_STORAGE_READ);
                if (fileStorage == 0) continue;
                maceFilterUser = (CvMat *)cvReadByName(fileStorage, 0, "maceFilter", 0);
                int PSLR = cvReadIntByName(fileStorage, 0, "thresholdPSLR", 100);
                int value = peakToSideLobeRatio(maceFilterUser, face, FACE_MACE_SIZE);

                cvReleaseFileStorage(&fileStorage);
                cvReleaseMat(&maceFilterUser);

                fileStorage = cvOpenFileStorage(eyePath, 0, CV_STORAGE_READ );
                if (fileStorage == 0) continue;

                maceFilterUser = (CvMat *)cvReadByName(fileStorage, 0, "maceFilter", 0);
                PSLR += cvReadIntByName(fileStorage, 0, "thresholdPSLR", 100);
                value += peakToSideLobeRatio(maceFilterUser, eye, EYE_MACE_SIZE);

                cvReleaseFileStorage(&fileStorage);
                cvReleaseMat(&maceFilterUser);

                fileStorage = cvOpenFileStorage(insideFacePath, 0, CV_STORAGE_READ);
                if (fileStorage == 0) continue;

                maceFilterUser = (CvMat *)cvReadByName(fileStorage, 0, "maceFilter", 0);
                PSLR += cvReadIntByName(fileStorage, 0, "thresholdPSLR", 100);
                value += peakToSideLobeRatio(maceFilterUser, insideFace, INSIDE_FACE_MACE_SIZE);

                int threshold = int(PSLR*newConfig->percentage);
                int pcent = int(((double)value / (double)PSLR)*100);
                int lowerPcent = int(newConfig->percentage*100.0);
                int upperPcent = int((newConfig->percentage+((1-newConfig->percentage)/4))*100.0);
                //  printf("Current Percent %d Lower %d Upper %d\n", pcent, lowerPcent,upperPcent);

                if (pcent >= upperPcent)
                {
                    count = 1;
                    break;
                }
                else if (pcent < lowerPcent)
                {
                }
                else
                {
                    double newThres = thresholdLBP + (double(double(pcent-lowerPcent) /
                                                      double(upperPcent-lowerPcent))*double(step));
                    // printf("New Thres %e\n", newThres);

                    if (val < newThres)
                    {
                        count = 1;
                        break;
                    }
                }

                // int percentage = int( (double(value)/double(PSLR))*100.0);
                // printf("%d \n",percentage);
                cvReleaseFileStorage(&fileStorage);
                cvReleaseMat(&maceFilterUser);
            }
        }
    }

    cvReleaseImage(&face);
    cvReleaseImage(&faceGray);
    cvReleaseImage(&eye);
    cvReleaseImage(&insideFace);

    if (k == 0) return 2;
    if (count == 1)
    {
        // printf("\n YES \n");
        return 1;
    }
    else
    {
        return 0;
    }
}

//------------------------------------------------------------------------------
/*
allFaces* verifier::getFaceImagesFromAllSet()
{
    setFace* faceSetStruct=getFaceSet();
    int i=0;
    char modelDir[300];
    struct dirent *de=NULL;
    DIR *d=NULL;
    list<string> * mylist=new list<string>;
    list<string>::iterator it;
    int k=0;
    for (i=0;i<faceSetStruct.count;i++)
    {
        sprintf(modelDir,"%s/%s",facesDirectory,faceSetStruct->setName[i]);
        // printf("%s \n",modelDir);
        d=opendir(modelDir);
        while (de = readdir(d))
        {
            if (!((strcmp(de->d_name, ".")==0) || (strcmp(de->d_name, "..")==0)))
            {
                k++;
                char fullPath[300];
                sprintf(fullPath,"%s/%s",modelDir,de->d_name);
                mylist->push_back (fullPath);
            }
        }
        mylist->sort();
    }


    allFaces* newAllFaces=new allFaces;
    newAllFaces.count=0;
    if (k==0)
        return newAllFaces;
    newAllFaces->faceImages =new IplImage *[(int) mylist->size()];
    newAllFaces.count =(int) mylist->size();
    int index=0;

    for (it=mylist->begin(); it!=mylist->end(); ++it)
    {

        string l=*it;
        char *p;
        char * path=new char[300];
        p=&l[0];
        sprintf(path,"%s",p);
        newAllFaces->faceImages[index]=cvLoadImage(path,1);
        index++;

    }

    return newAllFaces;
}

*/

//------------------------------------------------------------------------------
setFace* verifier::getFaceSet()
{
    struct dirent* de = NULL;
    DIR* d = NULL;
    int count = 0;

    list<string>* mylist = new list<string>;
    list<string>::iterator it;

    d = opendir(facesDirectory.c_str());

    while (de = readdir(d))
    {
        if (!((strcmp(de->d_name, ".") == 0) || (strcmp(de->d_name, "..") == 0)))
        {
            mylist->push_back(de->d_name);
            count++;
        }
    }

    mylist->sort();

    setFace* setFaceStruct = new setFace;
    setFaceStruct->setName = new char* [(int) mylist->size()];
    setFaceStruct->setFilePathThumbnails = new char* [(int) mylist->size()];
    setFaceStruct->faceImages = new structFaceImages[(int) mylist->size()];
    setFaceStruct->count = count;

    ///./setFaceStruct->faceImages.count=imageK;

    int k=0;
    for (it = mylist->begin(); it != mylist->end(); ++it)
    {
        string l = *it;
        char* p;
        char* setName=new char[300];
        char * fileThumb=new char[300];
        char*  imagesDir=new char[300];
        int imageK = 0, imageIndex=0;
        struct dirent* de = NULL;
        DIR* d = NULL;

        p = &l[0];
        sprintf(setName, "%s", p);
        setFaceStruct->setName[k] = setName;

        sprintf(fileThumb, "%s/%s/1.jpg", facesDirectory.c_str(), p);
        setFaceStruct->setFilePathThumbnails[k] = fileThumb;

        sprintf(imagesDir,"%s/%s",facesDirectory.c_str(), p);

        list<string>* mylistImages = new list<string>;
        list<string>::iterator itImages;
        d = opendir(imagesDir);

        while (de = readdir(d))
        {
            if (!((strcmp(de->d_name, ".") == 0) || (strcmp(de->d_name, "..") == 0)))
            {
                imageK++;
                char fullPath[300];
                sprintf(fullPath, "%s/%s", imagesDir, de->d_name);
                mylistImages->push_back(fullPath);
            }
        }

        mylistImages->sort();
        setFaceStruct->faceImages[k].faces = new IplImage* [imageK];
        setFaceStruct->faceImages[k].count = imageK;

        for (itImages=mylistImages->begin(); itImages!=mylistImages->end(); ++itImages)
        {
            string l = *itImages;
            char* p;
            char fileName[300];

            p=&l[0];
            sprintf(fileName, "%s", p);
            setFaceStruct->faceImages[k].faces[imageIndex] = cvLoadImage(fileName, 1);
            imageIndex++;
        }

        k++;
    }

    return setFaceStruct;
}

