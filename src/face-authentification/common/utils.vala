/* utils.vala
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
    internal struct Config
    {
        public double percentage;

        public Config (double inPercentage = 0.0)
        {
            percentage = inPercentage;
        }

        public Config.file (string inConfigDir)
        {
            string filename = "%s/mace.xml".printf (inConfigDir);
            OpenCV.File.Storage storage = new OpenCV.File.Storage (filename, null, OpenCV.File.Mode.READ);
            percentage = storage.read_real_by_name (null, "percentage", 1.0);
        }

        public void
        save (string inConfigDir)
        {
            string filename = "%s/mace.xml".printf (inConfigDir);
            OpenCV.File.Storage storage = new OpenCV.File.Storage (filename, null, OpenCV.File.Mode.WRITE);
            storage.write_real ("percentage", percentage);
        }
    }

    internal struct Mace
    {
        public double                 threshold_pcer;
        public int                    threshold_pslr;
        public string                 mace_filter_name;
        public unowned OpenCV.Matrix? filter;

        public Mace ()
        {
        }

        public void
        save (string inPath)
        {
            string fullpath = "%s/%s".printf (inPath, mace_filter_name);
            OpenCV.File.Storage fs = new OpenCV.File.Storage (fullpath, null, OpenCV.File.Mode.WRITE);
            fs.write ("maceFilter", filter, OpenCV.File.AttributeList ());
            fs.write_int ("thresholdPSLR", threshold_pslr);
            fs.write_real ("thresholdPCER", threshold_pcer);
        }
    }

    /**
     * Check for Uniform Pattern
     *
     * @param inI check Intensity Value
     *
     * @return ``true`` if its Uniform Patterns , ``false`` otherwise
     */
    public bool
    check_bit (int inI)
    {
        int bit8 = (inI % 2);
        int bit7 = ((inI / 2)   % 2);
        int bit6 = ((inI / 4)   % 2);
        int bit5 = ((inI / 8)   % 2);
        int bit4 = ((inI / 16)  % 2);
        int bit3 = ((inI / 32)  % 2);
        int bit2 = ((inI / 64)  % 2);
        int bit1 = ((inI / 128) % 2);
        int bitVector[9] = { bit1, bit8, bit7, bit6, bit5, bit4, bit3, bit2, bit1};
        int current = bitVector[0];
        int count = 0;
        for (int i = 0; i < 9; ++i)
        {
            if (current != bitVector[i])
                count++;
            current = bitVector[i];
        }

        if (count > 2)
            return true;

        return false;
    }

    /**
     * Check for Uniform Pattern
     *
     * @param inImage Image Input
     * @param inPx X Co-ordinate
     * @param inPy Y Co-ordinate
     * @param inThreshold Threshold to Check
     *
     * @return 1 if its above , 0 otherwise
     */
    public double
    get_bit (OpenCV.IPL.Image inImage, double inPx, double inPy, double inThreshold)
    {
        if (inPx < 0 || inPy < 0 || inPx >= inImage.width || inPy >= inImage.height)
            return 0;
        else
        {
            OpenCV.Scalar s = OpenCV.Scalar.get_2D (inImage, (int)inPy, (int)inPx);
            if (s.val[0] >= inThreshold)
                return 1;
            else
                return 0;
        }
    }

    /**
     * Create LBP Hist Feature
     *
     * @param inImage Image Input
     * @param inFeaturesFinal Features Final
     */
    public void
    feature_lbp_hist (OpenCV.IPL.Image inImage, OpenCV.Matrix inFeaturesFinal)
    {
        inFeaturesFinal.zero ();

        int lbpArry[256];

        OpenCV.IPL.Image imgLBP = new OpenCV.IPL.Image (OpenCV.Size (inImage.width, inImage.height), 8, 1);
        imgLBP.zero ();
        for (int i = 0; i < inImage.height; ++i)
        {
            for (int j = 0; j < inImage.width; ++j)
            {
                int p1x,p2x,p3x,p4x,p5x,p6x,p7x,p8x;
                int p1y,p2y,p3y,p4y,p5y,p6y,p7y,p8y;

                p1x = j - 1;
                p1y = i - 1;
                p2x = j;
                p2y = i - 1;
                p3x = j + 1;
                p3y = i - 1;
                p4x = j + 1;
                p4y = i;
                p5x = j + 1;
                p5y = i + 1;
                p6x = j;
                p6y = i + 1;
                p7x = j - 1;
                p7y = i + 1;
                p8x = j - 1;
                p8y = i;
                OpenCV.Scalar s = OpenCV.Scalar.get_2D (inImage, i, j);

                double bit1 = 128 * get_bit (inImage, p1x, p1y, s.val[0]);
                double bit2 =  64 * get_bit (inImage, p2x, p2y, s.val[0]);
                double bit3 =  32 * get_bit (inImage, p3x, p3y, s.val[0]);
                double bit4 =  16 * get_bit (inImage, p4x, p4y, s.val[0]);
                double bit5 =   8 * get_bit (inImage, p5x, p5y, s.val[0]);
                double bit6 =   4 * get_bit (inImage, p6x, p6y, s.val[0]);
                double bit7 =   2 * get_bit (inImage, p7x, p7y, s.val[0]);
                double bit8 =   1 * get_bit (inImage, p8x, p8y, s.val[0]);
                OpenCV.Scalar s1 = OpenCV.Scalar (bit1 + bit2 + bit3 + bit4 + bit5 + bit6 + bit7 + bit8, 0, 0);
                imgLBP.set_2d(i, j, s1);
            }
        }

        int Nx = (int)GLib.Math.floor ((inImage.width ) / 35);
        int Ny = (int)GLib.Math.floor ((inImage.height) / 30);

        for (int i = 0; i < Ny; ++i)
        {
            for (int j = 0; j < Nx; ++j)
            {
                int count = 0;
                OpenCV.Scalar s = OpenCV.Scalar (0);

                for (int k = 0; k < 256; ++k)
                {
                    if (!check_bit (k))
                    {
                        inFeaturesFinal.set_2d(i * Nx * 59 + j * 59 + count, 0, s);
                        lbpArry[k] = count;
                        count++;
                    }
                    else
                    {
                        inFeaturesFinal.set_2d (i * Nx * 59 + j * 59 + 58, 0, s);
                        lbpArry[k] = 58;
                    }
                }

                int startX = 35 * j;
                int startY = 30 * i;
                for (int l = 0; l < 30; ++l)
                {
                    for (int m = 0; m < 35; ++m)
                    {
                        OpenCV.Scalar s0 = OpenCV.Scalar.get_2D (imgLBP, startY + l, startX + m);
                        int val = (int)s0.val[0];
                        OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (inFeaturesFinal, i * Nx * 59 + j * 59 + lbpArry[val], 0);
                        s1.val[0] += 1;
                        inFeaturesFinal.set_2d (i * Nx * 59 + j * 59 + lbpArry[val], 0, s1);
                    }
                }
            }
        }
    }

    /**
     * LBP Diff ChiSquar Distance
     *
     * @param inModel Model Feature
     * @param iTest Test Feature
     */
    public double
    lbp_diff (OpenCV.Matrix inModel, OpenCV.Matrix inTest)
    {
        double[,] weights = {
            { 1  , 1, 3, 1, 1   },
            { 1  , 2, 3, 2, 1   },
            { 1  , 2, 2, 2, 1   },
            { 0.3, 1, 1, 1, 0.3 }
        };

        double chiSquare = 0;
        for (int i = 0; i < 5; ++i)
        {
            for (int j = 0; j < 4; ++j)
            {
                for (int k = 0; k < 59; ++k)
                {
                    OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (inModel, i * 4 * 59 + j * 59 + k, 0);
                    OpenCV.Scalar s2 = OpenCV.Scalar.get_2D (inTest, i * 4 * 59 + j * 59 + k, 0);
                    double hist1 = s1.val[0];
                    double hist2 = s2.val[0];

                    if ((hist1 + hist2) != 0)
                        chiSquare += (weights[j,i] * (GLib.Math.pow (hist1 - hist2, 2) / (hist1 + hist2)));
                }
            }
        }

        return chiSquare;
    }

    /**
     * Computes Mace ( Minimum Average Correlation Energy ) Filter for the Set of Images
     *
     * @param inImages Array of IplImages
     * @param inSizeOfImage Size of the Resized Image
     *
     * @return 2D Fourier Space Filter
     */
    internal OpenCV.Matrix
    compute_mace (OpenCV.IPL.Image[] inImages, int inSizeOfImage)
    {
        OpenCV.IPL.Image[] faces = new OpenCV.IPL.Image[inImages.length];
        OpenCV.IPL.Image[] grayfaces = new OpenCV.IPL.Image[inImages.length];

        for (int index = 0; index < inImages.length; ++index)
        {
            faces[index] = new OpenCV.IPL.Image (OpenCV.Size (inImages[index].width, inImages[index].height), 8, (OpenCV.IPL.Image.LoadType)1 );
            inImages[index].convert_color (faces[index], OpenCV.ColorConvert.BGR2GRAY);
        }

        int size_of_image_2x = inSizeOfImage * 2;
        int total_pixel = size_of_image_2x * size_of_image_2x;

        OpenCV.Matrix D                      = new OpenCV.Matrix (total_pixel        , 1                  , OpenCV.Type.FC64_2);
        OpenCV.Matrix DINV                   = new OpenCV.Matrix (total_pixel        , 1                  , OpenCV.Type.FC64_2);
        OpenCV.Matrix S                      = new OpenCV.Matrix (total_pixel        , inImages.length    , OpenCV.Type.FC64_2);
        OpenCV.Matrix SPLUS                  = new OpenCV.Matrix (inImages.length    , total_pixel        , OpenCV.Type.FC64_2);
        OpenCV.Matrix SPLUS_DINV             = new OpenCV.Matrix (inImages.length    , total_pixel        , OpenCV.Type.FC64_2);
        OpenCV.Matrix DINV_S                 = new OpenCV.Matrix (total_pixel        , inImages.length    , OpenCV.Type.FC64_2);
        OpenCV.Matrix SPLUS_DINV_S           = new OpenCV.Matrix (inImages.length    , inImages.length    , OpenCV.Type.FC64_2);
        OpenCV.Matrix SPLUS_DINV_S_INV       = new OpenCV.Matrix (inImages.length    , inImages.length    , OpenCV.Type.FC64_2);
        OpenCV.Matrix SPLUS_DINV_S_INV_1     = new OpenCV.Matrix (2 * inImages.length, 2 * inImages.length, OpenCV.Type.FC64_1);
        OpenCV.Matrix SPLUS_DINV_S_INV_1_INV = new OpenCV.Matrix (2 * inImages.length, 2 * inImages.length, OpenCV.Type.FC64_1);
        OpenCV.Matrix Hmace                  = new OpenCV.Matrix (total_pixel        , inImages.length    , OpenCV.Type.FC64_2);
        OpenCV.Matrix Cvalue                 = new OpenCV.Matrix (inImages.length    , 1                  , OpenCV.Type.FC64_2);
        OpenCV.Matrix Hmace_FIN              = new OpenCV.Matrix (total_pixel        , 1                  , OpenCV.Type.FC64_2);

        for (int i = 0; i < total_pixel; ++i)
        {
            OpenCV.Scalar s = OpenCV.Scalar (0, 0);
            D.set_2d (i, 0, s);
            DINV.set_2d (i, 0, s);
        }

        for (int i = 0; i < inImages.length; i++)
        {
            grayfaces[i] = new OpenCV.IPL.Image (OpenCV.Size (inSizeOfImage, inSizeOfImage), 8, 1);
            faces[i].resize (grayfaces[i], OpenCV.IPL.InterpolationType.LINEAR);
            grayfaces[i].equalize_hist (grayfaces[i]);

            OpenCV.IPL.Image realInput       = new OpenCV.IPL.Image (grayfaces[i].get_size (), OpenCV.IPL.DEPTH_64F, 1);
            OpenCV.IPL.Image realInputDouble = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
            OpenCV.IPL.Image imaginaryInput  = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
            OpenCV.IPL.Image complexInput    = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 2);

            OpenCV.MatrixStruct tmp = OpenCV.MatrixStruct ();
            grayfaces[i].convert_scale (realInput, 1.0, 0.0);
            realInputDouble.zero ();
            imaginaryInput.zero ();
            realInputDouble.get_subrectangle (tmp.to_pointer (), OpenCV.Rectangle (0, 0, inSizeOfImage, inSizeOfImage));
            realInput.copy (tmp.to_pointer ());

            realInputDouble.merge (imaginaryInput, null, null, complexInput);

            OpenCV.Matrix dftImage = new OpenCV.Matrix (size_of_image_2x, size_of_image_2x, OpenCV.Type.FC64_2);
            dftImage.get_subrectangle (tmp.to_pointer (), OpenCV.Rectangle (0, 0, size_of_image_2x, size_of_image_2x));
            complexInput.copy (tmp.to_pointer (), null);
            dftImage.DFT (dftImage, OpenCV.DXT_FORWARD, 0);

            for (int l = 0; l < size_of_image_2x; ++l)
            {
                for (int m = 0; m < size_of_image_2x; ++m)
                {
                    OpenCV.Scalar scalar = OpenCV.Scalar.get_2D (dftImage, l, m);
                    S.set_2d (l * size_of_image_2x + m, i, scalar);

                    OpenCV.Scalar scalarConj = OpenCV.Scalar (scalar.val[0], -scalar.val[1]);
                    SPLUS.set_2d (i, l * size_of_image_2x + m, scalarConj);
                    double val = ((GLib.Math.pow (scalar.val[0], 2) + GLib.Math.pow (scalar.val[1], 2)));

                    OpenCV.Scalar s = OpenCV.Scalar.get_2D (D, l * size_of_image_2x + m, 0);
                    s.val[0] = s.val[0] + val;
                    s.val[1] = 0;
                    D.set_2d (l * size_of_image_2x + m, 0, s);
                }
            }
        }

        for (int i = 0; i < total_pixel; ++i)
        {

            OpenCV.Scalar s= OpenCV.Scalar.get_2D (D, i, 0);
            s.val[0] = ((size_of_image_2x * size_of_image_2x * inImages.length) / GLib.Math.sqrt (s.val[0]));
            s.val[1] = 0;

            DINV.set_2d (i, 0, s);
        }

        for (int l = 0; l < inImages.length; ++l)
        {
            for (int m = 0; m < total_pixel; ++m)
            {
                OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (DINV, m, 0);
                OpenCV.Scalar s2 = OpenCV.Scalar.get_2D (SPLUS, l, m);
                OpenCV.Scalar s3 = OpenCV.Scalar.get_2D (S, m, l);

                s2.val[0] *= s1.val[0];
                s2.val[1] *= s1.val[0];

                s3.val[0] *= s1.val[0];
                s3.val[1] *= s1.val[0];

                SPLUS_DINV.set_2d(l, m, s2);
                DINV_S.set_2d(m, l, s3);
            }
        }
        SPLUS_DINV.matrix_multiply (S, SPLUS_DINV_S);

        for (int l = 0; l < inImages.length; ++l)
        {
            for (int m = 0; m < inImages.length; ++m)
            {
                OpenCV.Scalar s1= OpenCV.Scalar.get_2D (SPLUS_DINV_S, l, m);
                OpenCV.Scalar s2 = OpenCV.Scalar (s1.val[0], 0);

                SPLUS_DINV_S_INV_1.set_2d (l, m, s2);
                SPLUS_DINV_S_INV_1.set_2d (l + inImages.length, m + inImages.length, s2);

                s2.val[0]=s1.val[1];
                s2.val[1]=0;

                SPLUS_DINV_S_INV_1.set_2d (l, m + inImages.length, s2);

                s2.val[0] = -s1.val[1];
                s2.val[1]=0;

                SPLUS_DINV_S_INV_1.set_2d (l + inImages.length, m,s2);
            }
        }

        SPLUS_DINV_S_INV_1.invert (SPLUS_DINV_S_INV_1_INV);
        for (int l = 0; l < inImages.length; ++l)
        {
            for (int m = 0; m < inImages.length; ++m)
            {
                OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (SPLUS_DINV_S_INV_1_INV, l, m);
                OpenCV.Scalar s2 = OpenCV.Scalar.get_2D (SPLUS_DINV_S_INV_1_INV, l, m + inImages.length);
                OpenCV.Scalar s3 = OpenCV.Scalar (s1.val[0], s2.val[0]);

                SPLUS_DINV_S_INV.set_2d (l, m, s3);
            }
        }

        DINV_S.matrix_multiply (SPLUS_DINV_S_INV, Hmace);

        for (int l = 0; l < inImages.length; ++l)
        {
            OpenCV.Scalar s3 = OpenCV.Scalar (1, 0);
            Cvalue.set_2d (l, 0, s3);
        }
        Hmace.matrix_multiply (Cvalue, Hmace_FIN);

        OpenCV.Matrix maceFilterVisualize = new OpenCV.Matrix (size_of_image_2x, size_of_image_2x, OpenCV.Type.FC64_2);
        for (int l = 0; l < size_of_image_2x; ++l)
        {
            for (int m = 0; m < size_of_image_2x; ++m)
            {
                OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (Hmace_FIN, (l * size_of_image_2x + m), 0);
                maceFilterVisualize.set_2d(l, m, s1);
            }
        }

        return maceFilterVisualize;
    }

    /**
     * Tranformation to shift Quadrants to put (0,0) -  (center,center)
     *
     * @param inSrcArr Image input
     * @param inDstArr Image output
     */
    public void
    shift_dft (OpenCV.Array inSrcArr, OpenCV.Array inDstArr)
    {
        OpenCV.MatrixStruct q1stub = OpenCV.MatrixStruct ();
        OpenCV.MatrixStruct q2stub = OpenCV.MatrixStruct ();
        OpenCV.MatrixStruct q3stub = OpenCV.MatrixStruct ();
        OpenCV.MatrixStruct q4stub = OpenCV.MatrixStruct ();
        OpenCV.MatrixStruct d1stub = OpenCV.MatrixStruct ();
        OpenCV.MatrixStruct d2stub = OpenCV.MatrixStruct ();
        OpenCV.MatrixStruct d3stub = OpenCV.MatrixStruct ();
        OpenCV.MatrixStruct d4stub = OpenCV.MatrixStruct ();
        unowned OpenCV.Matrix q1, q2, q3, q4;
        unowned OpenCV.Matrix d1, d2, d3, d4;

        OpenCV.Size size = inSrcArr.get_size ();
        OpenCV.Size dst_size = inDstArr.get_size ();
        int cx, cy;

        if (dst_size.width != size.width || dst_size.height != size.height)
        {
            Log.error ("Source and Destination arrays must have equal sizes");
            return;
        }

        cx = size.width / 2;
        cy = size.height / 2;

        q1 = inSrcArr.get_subrectangle (q1stub.to_pointer (),  OpenCV.Rectangle (0 ,  0 ,  cx,  cy));
        q2 = inSrcArr.get_subrectangle (q2stub.to_pointer (),  OpenCV.Rectangle (cx,  0 ,  cx,  cy));
        q3 = inSrcArr.get_subrectangle (q3stub.to_pointer (),  OpenCV.Rectangle (cx,  cy,  cx,  cy));
        q4 = inSrcArr.get_subrectangle (q4stub.to_pointer (),  OpenCV.Rectangle (0 ,  cy,  cx,  cy));
        d1 = inSrcArr.get_subrectangle (d1stub.to_pointer (),  OpenCV.Rectangle (0 ,  0 ,  cx,  cy));
        d2 = inSrcArr.get_subrectangle (d2stub.to_pointer (),  OpenCV.Rectangle (cx,  0 ,  cx,  cy));
        d3 = inSrcArr.get_subrectangle (d3stub.to_pointer (),  OpenCV.Rectangle (cx,  cy,  cx,  cy));
        d4 = inSrcArr.get_subrectangle (d4stub.to_pointer (),  OpenCV.Rectangle (0 ,  cy,  cx,  cy));

        if (inSrcArr != inDstArr)
        {
            if (!q1.are_types_eq (d1))
            {
                Log.error ("Source and Destination arrays must have the same format");
                return;
            }

            q3.copy (d1);
            q4.copy (d2);
            q1.copy (d3);
            q2.copy (d4);
        }
        else
        {
            OpenCV.Matrix tmp = new OpenCV.Matrix (size.height / 2, size.width / 2, inSrcArr.get_elem_type ());

            q3.copy  (tmp);
            q1.copy  (q3);
            tmp.copy (q1);
            q4.copy  (tmp);
            q2.copy  (q4);
            tmp.copy (q2);
        }
    }

    /**
     * Computes peakCorrPlaneEnergy of Filter and Image
     *
     * @param inMaceFilterVisualize 2D Fourier Space Filter
     * @param inImage Test Image
     * @param inSizeOfImage Size of the Resized Image
     *
     * @return peakCorrPlaneEnergy
     */
    internal double
    peak_corr_plane_energy (OpenCV.Matrix inMaceFilterVisualize, OpenCV.IPL.Image inImage, int inSizeOfImage)
    {
        OpenCV.MatrixStruct tmp = OpenCV.MatrixStruct ();
        OpenCV.IPL.Image face = new OpenCV.IPL.Image (OpenCV.Size (inImage.width, inImage.height), 8, 1);
        inImage.convert_color (face, OpenCV.ColorConvert.BGR2GRAY);

        OpenCV.IPL.Image grayImage = new OpenCV.IPL.Image (OpenCV.Size (inSizeOfImage,inSizeOfImage), 8, 1);
        face.resize (grayImage, OpenCV.IPL.InterpolationType.LINEAR);
        grayImage.equalize_hist (grayImage);

        int size_of_image_2x = inSizeOfImage * 2;

        OpenCV.IPL.Image realInput       = new OpenCV.IPL.Image (OpenCV.Size (inSizeOfImage, inSizeOfImage), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image realInputDouble = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image imaginaryInput  = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image complexInput    = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 2);

        imaginaryInput.zero ();
        realInputDouble.zero ();

        grayImage.convert_scale (realInput, 1.0, 0.0);

        realInputDouble.get_subrectangle (tmp.to_pointer (), OpenCV.Rectangle (0, 0, inSizeOfImage, inSizeOfImage));
        realInput.copy (tmp.to_pointer ());
        realInputDouble.merge (imaginaryInput, null, null, complexInput);

        OpenCV.Matrix dftImage = new OpenCV.Matrix (size_of_image_2x, size_of_image_2x, OpenCV.Type.FC64_2);
        dftImage.get_subrectangle (tmp.to_pointer (), OpenCV.Rectangle (0, 0, size_of_image_2x, size_of_image_2x));
        complexInput.copy (tmp.to_pointer ());
        dftImage.DFT (dftImage, OpenCV.DXT_FORWARD, 0);
        dftImage.multiply_spectrums (inMaceFilterVisualize, dftImage, OpenCV.DXT_MUL_CONJ);
        dftImage.DFT (dftImage ,OpenCV.DXT_INV_SCALE, 0);

        OpenCV.IPL.Image image_Re = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image image_Im = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);

        dftImage.split (image_Re, image_Im, null, null);
        shift_dft (image_Re, image_Re);

        double m1,M1;
        OpenCV.Point p1,p2;
        image_Re.min_max_loc (out m1, out M1, out p1, out p2, null);
        double valueOfPCER = 0;
        for (int l = 0; l < size_of_image_2x; ++l)
        {
            for (int m = 0; m < size_of_image_2x; ++m)
            {
                OpenCV.Scalar scalar = OpenCV.Scalar.get_2D (image_Re, l, m);
                valueOfPCER += scalar.val[0];
            }
        }

        return M1 / GLib.Math.sqrt (valueOfPCER);
    }

    /**
     * Computes PSLR of Filter and Image
     *
     * @param inMaceFilterVisualize 2D Fourier Space Filter
     * @param inImage Test Image
     * @param inSizeOfImage Size to Resize to
     *
     * @return peakToSideLobeRatio
     */
    public int
    peak_to_side_lobe_ratio (OpenCV.Matrix inMaceFilterVisualize, OpenCV.IPL.Image inImage, int inSizeOfImage)
    {
        OpenCV.IPL.Image face = new OpenCV.IPL.Image (OpenCV.Size (inImage.width, inImage.height), 8, 1);
        inImage.convert_color (face, OpenCV.ColorConvert.BGR2GRAY);

        OpenCV.IPL.Image grayImage = new OpenCV.IPL.Image (OpenCV.Size (inSizeOfImage,inSizeOfImage), 8, 1);
        face.resize (grayImage, OpenCV.IPL.InterpolationType.LINEAR);
        grayImage.equalize_hist (grayImage);

        int size_of_image_2x = inSizeOfImage * 2;

        OpenCV.IPL.Image realInput       = new OpenCV.IPL.Image (OpenCV.Size (inSizeOfImage, inSizeOfImage), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image realInputDouble = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image imaginaryInput  = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image complexInput    = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 2);

        grayImage.convert_scale (realInput, 1.0, 0.0);

        imaginaryInput.zero ();
        realInputDouble.zero ();

        OpenCV.MatrixStruct tmp = OpenCV.MatrixStruct ();
        realInputDouble.get_subrectangle (tmp.to_pointer (), OpenCV.Rectangle (0, 0, inSizeOfImage, inSizeOfImage));
        realInput.copy (tmp.to_pointer ());
        realInputDouble.merge (imaginaryInput, null, null, complexInput);

        OpenCV.Matrix dftImage = new OpenCV.Matrix (size_of_image_2x, size_of_image_2x, OpenCV.Type.FC64_2);
        dftImage.get_subrectangle (tmp.to_pointer (), OpenCV.Rectangle (0, 0, size_of_image_2x, size_of_image_2x));
        complexInput.copy (tmp.to_pointer (), null);
        dftImage.DFT (dftImage, OpenCV.DXT_FORWARD, 0);
        dftImage.multiply_spectrums (inMaceFilterVisualize, dftImage, OpenCV.DXT_MUL_CONJ);
        dftImage.DFT (dftImage ,OpenCV.DXT_INV_SCALE, 0);

        OpenCV.IPL.Image image_Re = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);
        OpenCV.IPL.Image image_Im = new OpenCV.IPL.Image (OpenCV.Size (size_of_image_2x, size_of_image_2x), OpenCV.IPL.DEPTH_64F, 1);

        dftImage.split (image_Re, image_Im, null, null);
        shift_dft (image_Re, image_Re);

        double m1,M1;
        OpenCV.Point p1,p2;
        image_Re.min_max_loc (out m1, out M1, out p1, out p2, null);
        image_Re.convert_scale (image_Re, 1.0, 1.0 * (-m1));
        image_Re.min_max_loc (out m1, out M1, out p1, out p2, null);

        int rad1 = (int)GLib.Math.floor ((double)(45.0 / 64.0) * (double)inSizeOfImage);
        int rad2 = (int)GLib.Math.floor ((double)(27.0 / 64.0) * (double)inSizeOfImage);

        double val = 0;
        double num = 0;

        for (int l = 0; l < size_of_image_2x; ++l)
        {
            for (int m = 0; m < size_of_image_2x; ++m)
            {
                double rad = GLib.Math.sqrt ((GLib.Math.pow (m - inSizeOfImage, 2) + GLib.Math.pow (l - inSizeOfImage, 2)));

                if (rad < rad1 && rad > rad2)
                {
                    OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (image_Re, l, m);
                    val += s1.val[0];
                    num++;
                }
            }
        }
        val = val / num;

        double std2 = 0;
        for (int l = 0; l < size_of_image_2x; ++l)
        {
            for (int m = 0; m < size_of_image_2x; ++m)
            {
                double rad = GLib.Math.sqrt ((GLib.Math.pow (m - inSizeOfImage, 2) + GLib.Math.pow (l - inSizeOfImage, 2)));
                if (rad < rad1 && rad > rad2)
                {
                    OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (image_Re, l, m);
                    std2 += GLib.Math.pow (val - s1.val[0], 2);
                }
            }
        }

        std2 /= num;
        std2 = GLib.Math.sqrt (std2);
        OpenCV.Scalar sca = OpenCV.Scalar.get_2D (image_Re, inSizeOfImage, inSizeOfImage);
        return (int)GLib.Math.floor ((sca.val[0] - val) / std2);
    }

    /**
     * Computes Center of Mass of Image in a Particular Direction
     *
     * @param inSrc Source Image
     * @param inFlagXY  direction, 0 -X , 1 -Y
     *
     * @return Co-ordinate
     */
    public double
    center_of_mass(OpenCV.IPL.Image inSrc, bool inFlagXY)
    {
        OpenCV.PixelPosition8u? pos_src = (OpenCV.PixelPosition8u?)GLib.malloc (sizeof (OpenCV.PixelPosition8u));
        OpenCV.PixelPosition8u.init_pixel (pos_src, inSrc.image_data, inSrc.width_step, inSrc.get_size (), 0, 0, inSrc.origin);

        int to1;
        int to2;
        if (!inFlagXY)
        {
            to1 = inSrc.width;
            to2 = inSrc.height;
        }
        else
        {
            to1 = inSrc.height;
            to2 = inSrc.width;
        }

        uchar* ptr_src;
        uchar Intensity;
        double sumPixels[400];
        double totalX2=0;
        double totalX1=0;
        double totalX0=0;
        for (int x = 0; x < to1; ++x)
        {
            sumPixels[x] = 0;
            for (int y = 0; y < to2; ++y)
            {
                if (!inFlagXY)
                    ptr_src = pos_src.move_to (x, y, 1);
                else
                    ptr_src = pos_src.move_to (y, x, 1);

                Intensity = ptr_src[0];

                if (Intensity < 140 || Intensity > 200)
                    sumPixels[x] += 255 - Intensity;

            }


            totalX2 += (sumPixels[x] * (x + 1));
            totalX1 += (sumPixels[x]);
        }
        totalX0 = totalX2 / totalX1;
        return totalX0;
    }

    /**
     * Rotates an Image By an Angle
     *
     * @param inAngle Angle at which Point should be turned
     * @param inCentreX Pivot Center X Co-ordinate
     * @param inCentreY Pivot gg Y Co-ordinate
     * @param inImg Source Image
     * @param inDstImg Destination Image
     */
    public void
    rotate(double inAngle, float inCentreX, float inCentreY, OpenCV.IPL.Image inImg, OpenCV.IPL.Image inDstImg)
    {
        OpenCV.Matrix translate = new OpenCV.Matrix (2, 3, OpenCV.Type.FC32_1);
        OpenCV.Point2D32f centre = OpenCV.Point2D32f (inCentreX, inCentreY);

        centre.rotation_matrix (inAngle, 1.0, translate);
        inImg.warp_affine (inDstImg, translate, OpenCV.INTER_LINEAR + OpenCV.WARP_FILL_OUTLIERS, OpenCV.Scalar.all (0));
    }

    /**
     * Paints the Spotlight Ellipse Effect
     *
     * @param inImage Image to be painted upon
     * @param inLeftEye left eye cordinates
     * @param inRightEye right eye cordinates
     */
    public void
    paint_cyclops (OpenCV.IPL.Image inImage, OpenCV.Point inLeftEye, OpenCV.Point inRightEye)
    {
        OpenCV.IPL.Image imgDest = new OpenCV.IPL.Image (OpenCV.Size (inImage.width, inImage.height), 8, 3);
        imgDest.zero ();

        OpenCV.Point p2 = OpenCV.Point (inLeftEye.x, inLeftEye.y);
        double yvalue = inRightEye.y - inLeftEye.y;
        double xvalue = inRightEye.x - inLeftEye.x;
        double width  = GLib.Math.sqrt (GLib.Math.pow (xvalue, 2) + GLib.Math.pow (yvalue, 2));
        double ratio  = GLib.Math.sqrt (GLib.Math.pow (xvalue, 2) + GLib.Math.pow (yvalue, 2)) / 80.0;

        p2.x += (int)(width / 2.0);
        p2.y += (int)(35 * ratio);

        double ang= -GLib.Math.atan (yvalue / xvalue) * (180 / GLib.Math.PI);
        OpenCV.Matrix rotateMatrix = new OpenCV.Matrix (2, 3, OpenCV.Type.FC32_1);
        OpenCV.Point2D32f centre = OpenCV.Point2D32f (inLeftEye.x, inLeftEye.y);
        centre.rotation_matrix (ang, 1.0, rotateMatrix);

        p2.x= (int)GLib.Math.floor (p2.x * rotateMatrix [0, 0] +  p2.y * rotateMatrix [0, 1] + rotateMatrix [0, 2]);
        p2.y= (int)GLib.Math.floor (p2.x * rotateMatrix [1, 0] +  p2.y * rotateMatrix [1, 1] + rotateMatrix [1, 2]);

        imgDest.ellipse (p2, OpenCV.Size ((int)(width / 2) + (int)(55 * ratio), (int)(120 * ratio)), ang, 0, 360, OpenCV.Scalar (255, 255, 255));
        for (int i = 0; i < inImage.height; ++i)
        {
            for (int j = 0; j < inImage.width; ++j)
            {
                OpenCV.Scalar s = OpenCV.Scalar.get_2D (imgDest, i, j);
                if (s.val[0] != 255)
                {
                    OpenCV.Scalar s1 = OpenCV.Scalar.get_2D (inImage, i, j);
                    s1.val[0] = s1.val[0] * 0.45;
                    s1.val[1] = s1.val[1] * 0.45;
                    s1.val[2] = s1.val[2] * 0.45;
                    inImage.set_2d (i, j, s1);
                }
            }
        }
    }
}
