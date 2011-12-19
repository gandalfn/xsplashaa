/* tracker.vala
 *
 * Copyright (C) 2009-2011  Nicolas Bruguier
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
 *  Nicolas Bruguier <nicolas.bruguier@supersonicimagine.fr>
 */

namespace XSAA.FaceAuthentification
{
    /**
     * INTEGRAL AND VARIANCE PROJECTION TRACKER CLASS
     */
    public class Tracker : GLib.Object
    {
        // constants
        const int NUMBER_OF_GRID_POINTS = 25;
        const int GRID_SIDE_SIZE = 5;

        // properties
        private double   m_StateVariableScaleX;
        private double   m_StateVariableTranslateX;
        private double   m_StateVariableScaleY;
        private double   m_StateVariableTranslateY;
        private double   m_LastImageWidth;
        private double   m_LastImageHeight;
        private double[] m_TrackerModelFeatureVARIANCEX;
        private double[] m_TrackerModelFeatureVARIANCEY;
        private double[] m_TrackerModelFeatureINTEGRALX;
        private double[] m_TrackerModelFeatureINTEGRALY;
        private int      m_TrackerModelFeatureSizeX;
        private int      m_TrackerModelFeatureSizeY;

        // accessors
        /**
         * Error Value between last image from track call and truth image in Y
         */
        public double last_difference_1 { get; set; default = 0.0; }
        /**
         * Error Value between last image from track call and truth image in X
         */
        public double last_difference_2 { get; set; default = 0.0; }
        /**
         * Experimental - currently not used
         */
        public OpenCV.Point anchor_point { get; set; }

        // signals

        // methods
        /**
         * Create a integral and variance projection tracker object
         */
        public Tracker ()
        {
        }

        /**
         * Function used to find the difference between the feature of current
         * image and feature of model image
         * @param inFeature Input Feature
         * @param inFeatureModel Model Feature
         * @param inSize Size of Feature
         * @param inPx Scale Factor
         * @param inPy Translate Factor
         * @param inAnchor experimental - currently not used
         */
        private double
        difference (double[] inFeature, double[] inFeatureModel, int inSize, double inPx, double inPy, int inAnchor)
        {
            double diff = 0;
            for (int i = 0; i < inSize; ++i)
            {
                if ((inPx * i + inPy) >= 0 && (inPx * i + inPy) < inSize)
                {
                    int k = (int)GLib.Math.floor (inPx * i + inPy);
                    double decimal = inPx * i + inPy - k;
                    double val = inFeature[k] + decimal * (inFeature[k+1]- inFeature[k]);

                    if ((i > (int)(inAnchor - GLib.Math.floor (0.07 * inSize))) &&
                        ( i < (int)(inAnchor + GLib.Math.floor (0.07 * inSize))))
                    {
                        diff += (1.3 * GLib.Math.pow (inFeatureModel[i] - val, 2));
                    }
                    else
                    {
                        diff += (0.7 * GLib.Math.pow (inFeatureModel[i] -val, 2));
                    }
                }
            }

            return diff;
        }

        /**
         * Find Parameters
         *
         * @param inScaleFactor Last Updated Scale Factor
         * @param inTranslateFactor Last Updated Translate Factor
         * @param outUpdatedScaleFactor New Scale Factor
         * @param outUpdatedTranslateFactor New Translate Factor
         * @param inFeature feature Variance of Image
         * @param inFeature1 feature Integral of Image
         * @param inFeatureModel Variance Model Feature
         * @param inFeatureModel1 Integral Model Feature
         * @param inSize Not Used
         * @param inScale Scale Factor
         * @param inTranslate Translate Factor
         * @param inAnchor experimental - currently not used
         */
        private double find_param (double inScaleFactor, double inTranslateFactor,
                                   out double outUpdatedScaleFactor, out double outUpdatedTranslateFactor,
                                   double[] inFeature, double[] inFeature1, double[] inFeatureModel,
                                   double[] inFeatureModel1, int inSize, double inScale, double inTranslate,
                                   int inAnchor)
        {
            double px = inScaleFactor;
            double py = inTranslateFactor;
            outUpdatedScaleFactor = px;
            outUpdatedTranslateFactor = py;
            double[] diffVal1 = new double [NUMBER_OF_GRID_POINTS];
            double[] diffVal2 = new double [NUMBER_OF_GRID_POINTS];

            for (int i = 0; i < GRID_SIDE_SIZE; ++i)
            {
                for (int j = 0; j < GRID_SIDE_SIZE; ++j)
                {
                    px = inScaleFactor - i * inScale;
                    py = inTranslateFactor + j * inTranslate;
                    diffVal1[GRID_SIDE_SIZE * i + j] = difference (inFeature, inFeatureModel, inSize, px, py, inAnchor);
                    diffVal2[GRID_SIDE_SIZE * i + j] = difference (inFeature1, inFeatureModel1, inSize, px, py, inAnchor);
                }
            }

            int[] diffValRanks1 = new int[NUMBER_OF_GRID_POINTS];
            int[] diffValRanks2 = new int[NUMBER_OF_GRID_POINTS];
            for (int i = 0; i < NUMBER_OF_GRID_POINTS; ++i)
            {
                diffValRanks1[i] = i;
                diffValRanks2[i] = i;
            }

            for(int i = 0; i < NUMBER_OF_GRID_POINTS; ++i)
            {
                for(int j = 0; j < (NUMBER_OF_GRID_POINTS - 1); ++j)
                {
                    if (diffVal1[diffValRanks1[j]] > diffVal1[diffValRanks1[j + 1]])
                    {
                        int temp = diffValRanks1[j];
                        diffValRanks1[j] = diffValRanks1[j + 1];
                        diffValRanks1[j + 1] = temp;
                    }
                    if (diffVal2[diffValRanks2[j]] > diffVal2[diffValRanks2[j + 1]])
                    {
                        int temp = diffValRanks2[j];
                        diffValRanks2[j] = diffValRanks2[j + 1];
                        diffValRanks2[j + 1] = temp;
                    }
                }
            }

            int[] diffValRanksRev1 = new int[NUMBER_OF_GRID_POINTS];
            int[] diffValRanksRev2 = new int[NUMBER_OF_GRID_POINTS];
            for (int i = 0; i < NUMBER_OF_GRID_POINTS; ++i)
            {
                for(int j = 0; j < NUMBER_OF_GRID_POINTS; ++j)
                {
                    if (diffValRanks1[j] == i) diffValRanksRev1[i] = j;
                    if (diffValRanks2[j] == i) diffValRanksRev2[i] = j;
                }
            }

            int[] sumRank = new int[NUMBER_OF_GRID_POINTS];
            for (int i = 0; i < NUMBER_OF_GRID_POINTS; ++i)
                sumRank[i] = diffValRanksRev2[i] + diffValRanksRev1[i];

            int min = NUMBER_OF_GRID_POINTS + 10;
            int ind = -1;
            for (int i = 0; i < NUMBER_OF_GRID_POINTS; ++i)
            {
                if (min > sumRank[i])
                {
                    min = sumRank[i];
                    ind = i;
                }
            }

            int i = ind / GRID_SIDE_SIZE;
            int j = ind - (i * GRID_SIDE_SIZE);
            px = inScaleFactor - i * inScale;
            py = inTranslateFactor + j * inTranslate;
            outUpdatedScaleFactor = px;
            outUpdatedTranslateFactor = py;

            return diffVal1[GRID_SIDE_SIZE * i + j] + diffVal2[GRID_SIDE_SIZE * i + j];
        }


        /**
         * Calculate the Features
         *
         * @param inInput input image for which the feature should be calculated
         * @param inFlag direction, X ``false`` or Y ``true``
         * @param inVarorintegral feature type, Variance ``false`` or Integral ``true``
         */
        private double[]
        calculate_feature (OpenCV.IPL.Image inInput, bool inFlag, bool inVarorintegral)
        {
            double[] integral;
            int lim1, lim2;

            if (inFlag)
            {
                integral = new double[inInput.width];
                lim1 = inInput.width;
                lim2 = inInput.height;
            }
            else
            {
                integral = new double[inInput.height];
                lim1 = inInput.height;
                lim2 = inInput.width;
            }

            for (int i = 0; i < lim1; ++i)
                integral[i] = 0;

            for(int i = 0; i < lim1; ++i)
            {
                for(int j = 0; j < lim2; ++j)
                {
                    OpenCV.Scalar s;
                    if (inFlag)
                        s = OpenCV.Scalar.get_2D (inInput, j, i);
                    else
                        s = OpenCV.Scalar.get_2D (inInput, i, j);

                    integral[i] += s.val[0];
                }

                integral[i] /= lim2;
            }

            double[] variance;
            double intSum = 0, varSum = 0;
            if (inFlag)
                variance = new double[inInput.width];
            else
                variance = new double[inInput.height];

            for (int i = 0; i < lim1; ++i)
            {
                variance[i] = 0;
                for (int j = 0; j < lim2; ++j)
                {
                    OpenCV.Scalar s;

                    if (inFlag)
                        s = OpenCV.Scalar.get_2D (inInput, j, i);
                    else
                        s = OpenCV.Scalar.get_2D (inInput, i, j);

                    variance[i] += GLib.Math.pow ((s.val[0] - integral[i]), 2);
                }

                variance[i] = GLib.Math.sqrt (variance[i] / lim2);
            }

            for (int i = 0; i < lim1; ++i)
            {
                intSum += integral[i];
                varSum += variance[i];
            }
            intSum = intSum / lim1;
            varSum = varSum / lim1;

            for(int i=0; i < lim1; i++)
            {
                integral[i] -= intSum;
                variance[i] -= varSum;
            }

            if (inVarorintegral)
                return integral;
            else
                return variance;
        }

        /**
         * Run grid search
         *
         * @param inGray input image for which the grid Search should be run on
         * @param inSize Size of the feature
         * @param inFlag direction, X ``false`` or Y ``true``
         * @param outD scale factor
         * @param outE translate factor
         * @param outVarianceImage feature Variance of Image
         * @param outIntegralImage feature Integral of Image
         */
        private double
        run_grid_search (OpenCV.IPL.Image inGray, int inSize, bool inFlag, out double outD,
                         out double outE, double[] inVarianceImage, double[] inIntegralImage, int inAnchor)
        {
            double dimension = 0;

            if (inFlag)
                dimension = (double)(inGray.width) * (double)((double)inSize / (double)inGray.height);
            else
                dimension = (double)(inGray.height) * (double)((double)inSize / (double)inGray.width);

            int dimension_floor = (int)GLib.Math.floor (dimension);
            OpenCV.IPL.Image gray_new;

            if (inFlag)
                gray_new = new OpenCV.IPL.Image (OpenCV.Size (dimension_floor, inSize), 8, 1);
            else
                gray_new = new OpenCV.IPL.Image (OpenCV.Size (inSize, dimension_floor), 8, 1);

            inGray.resize (gray_new, OpenCV.IPL.InterpolationType.LINEAR);

            double[] feature = calculate_feature (gray_new, inFlag, false);
            double[] feature1 = calculate_feature (gray_new, inFlag, true);

            double v = 0;
            double slLimitUp = 1.1;
            double tlLimidUp = -4;
            double slLimitLw = 0.9;
            double tlLimidLw = 4;
            double num = (GRID_SIDE_SIZE - 1);
            double scaleFactor = slLimitUp;
            double translateFactor = tlLimidUp;
            double updatedScaleFactor = scaleFactor;
            double updatedTranslateFactor = tlLimidUp;
            double scale = (slLimitUp-slLimitLw) / num;
            double translate = (tlLimidLw-tlLimidUp) / num;

            for (int l = 0; l < 6; ++l)
            {
                v = find_param (scaleFactor, translateFactor, out updatedScaleFactor,
                                out updatedTranslateFactor, feature, feature1, inVarianceImage,
                                inIntegralImage, inSize, scale, translate, inAnchor);

                scale /= 2;
                translate /= 2;
                scaleFactor = updatedScaleFactor + (num / 2) * scale;
                translateFactor = updatedTranslateFactor - (num / 2) * translate;

                if (translateFactor <= tlLimidUp) translateFactor = tlLimidUp;
                if (scaleFactor >= slLimitUp) scaleFactor = slLimitUp;
                if ((scaleFactor - num*scale) <= slLimitLw)
                    scaleFactor = slLimitLw + (num * scale);
                if ((translateFactor + num * translate) >= tlLimidLw)
                    translateFactor = tlLimidLw - (num*translate);
            }

            outD = scaleFactor;
            outE = translateFactor;

            return v;
        }

        /**
         * This function runs the tracker algorithm
         * @param input, Image on which tracker should run
         */
        public void
        track_image (OpenCV.IPL.Image inInput)
        {
            m_LastImageHeight = inInput.height;
            m_LastImageWidth = inInput.width;

            last_difference_1 = run_grid_search (inInput, m_TrackerModelFeatureSizeY, true,
                                                 out m_StateVariableScaleY, out m_StateVariableTranslateY,
                                                 m_TrackerModelFeatureVARIANCEY, m_TrackerModelFeatureINTEGRALY,
                                                 anchor_point.y);
            last_difference_2 = run_grid_search (inInput, m_TrackerModelFeatureSizeX, false,
                                                 out m_StateVariableScaleX, out m_StateVariableTranslateX,
                                                 m_TrackerModelFeatureVARIANCEX, m_TrackerModelFeatureINTEGRALX,
                                                 anchor_point.x);
        }

        /**
         * This function correlates the points between input and output
         *
         * @param outP1 Input Point Co-ordinates on Model Image
         * @param outP2 Output Point Co-ordinates on Current Image
         */
        public void
        find_point (OpenCV.Point inP1, ref OpenCV.Point outP2)
        {
            outP2.x = (int)GLib.Math.floor ((double)(m_StateVariableScaleX * (double)inP1.x +
                                                     (double)m_StateVariableTranslateX) *
                                            ((double)m_LastImageWidth / (double)m_TrackerModelFeatureSizeX));
            outP2.y = (int)GLib.Math.floor ((double)(m_StateVariableScaleY * (double)inP1.y +
                                                     (double)m_StateVariableTranslateY) *
                                            ((double)m_LastImageHeight / (double)m_TrackerModelFeatureSizeY));
        }

        /**
         * Sets the Model (the truth) of tracking
         *
         * @param inInput truth image
         */
        public void
        set_model (OpenCV.IPL.Image inInput)
        {
            m_TrackerModelFeatureSizeY = inInput.height;
            m_TrackerModelFeatureSizeX = inInput.width;

            //Variance
            m_TrackerModelFeatureVARIANCEY = calculate_feature (inInput, true, false);
            m_TrackerModelFeatureVARIANCEX = calculate_feature (inInput, false, false);
            //Integral
            m_TrackerModelFeatureINTEGRALY = calculate_feature (inInput, true, true);
            m_TrackerModelFeatureINTEGRALX = calculate_feature (inInput, false, true);
        }
    }
}
