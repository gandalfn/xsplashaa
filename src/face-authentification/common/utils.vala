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

            OpenCV.Matrix tmp = new OpenCV.Matrix (0, 0, 0);
            grayfaces[i].convert_scale (realInput, 1.0, 0.0);
            realInputDouble.zero ();
            imaginaryInput.zero ();
            realInputDouble.get_subrectangle (tmp, OpenCV.Rectangle (0, 0, inSizeOfImage, inSizeOfImage));
            realInput.copy (tmp);

            realInputDouble.merge (imaginaryInput, null, null, complexInput);

            OpenCV.Matrix dftImage = new OpenCV.Matrix (size_of_image_2x, size_of_image_2x, OpenCV.Type.FC64_2);
            dftImage.get_subrectangle (tmp, OpenCV.Rectangle (0, 0, size_of_image_2x, size_of_image_2x));
            complexInput.copy (tmp, null);
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
        OpenCV.Matrix tmp = null;
        OpenCV.Matrix q1stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix q2stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix q3stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix q4stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix d1stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix d2stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix d3stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix d4stub = new OpenCV.Matrix (0, 0, 0);
        OpenCV.Matrix q1, q2, q3, q4;
        OpenCV.Matrix d1, d2, d3, d4;

        OpenCV.Size size = inSrcArr.get_size ();
        OpenCV.Size dst_size = inDstArr.get_size ();
        int cx, cy;

        if (dst_size.width != size.width || dst_size.height != size.height)
        {
            Log.error ("Source and Destination arrays must have equal sizes");
            return;
        }

        if (inSrcArr == inDstArr)
        {
            tmp = new OpenCV.Matrix (size.height / 2, size.width / 2, inSrcArr.get_elem_type ());
        }

        cx = size.width / 2;
        cy = size.height / 2;

        q1 = inSrcArr.get_subrectangle (q1stub,  OpenCV.Rectangle (0 ,  0 ,  cx,  cy));
        q2 = inSrcArr.get_subrectangle (q2stub,  OpenCV.Rectangle (cx,  0 ,  cx,  cy));
        q3 = inSrcArr.get_subrectangle (q3stub,  OpenCV.Rectangle (cx,  cy,  cx,  cy));
        q4 = inSrcArr.get_subrectangle (q4stub,  OpenCV.Rectangle (0 ,  cy,  cx,  cy));
        d1 = inSrcArr.get_subrectangle (d1stub,  OpenCV.Rectangle (0 ,  0 ,  cx,  cy));
        d2 = inSrcArr.get_subrectangle (d2stub,  OpenCV.Rectangle (cx,  0 ,  cx,  cy));
        d3 = inSrcArr.get_subrectangle (d3stub,  OpenCV.Rectangle (cx,  cy,  cx,  cy));
        d4 = inSrcArr.get_subrectangle (d4stub,  OpenCV.Rectangle (0 ,  cy,  cx,  cy));

        if (inSrcArr != inDstArr)
        {
            if (!q1.are_types_eq (d1))
            {
                Log.error ("Source and Destination arrays must have the same format");
                return;
            }

            q3.copy (d1, null);
            q4.copy (d2, null);
            q1.copy (d3, null);
            q2.copy (d4, null);
        }
        else
        {
            q3.copy  (tmp, null);
            q1.copy  (q3,  null);
            tmp.copy (q1,  null);
            q4.copy  (tmp, null);
            q2.copy  (q4,  null);
            tmp.copy (q2,  null);
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

        OpenCV.Matrix tmp = new OpenCV.Matrix (0, 0, 0);
        realInputDouble.get_subrectangle (tmp, OpenCV.Rectangle (0, 0, inSizeOfImage, inSizeOfImage));
        realInput.copy (tmp);
        realInputDouble.merge (imaginaryInput, null, null, complexInput);

        OpenCV.Matrix dftImage = new OpenCV.Matrix (size_of_image_2x, size_of_image_2x, OpenCV.Type.FC64_2);
        dftImage.get_subrectangle (tmp, OpenCV.Rectangle (0, 0, size_of_image_2x, size_of_image_2x));
        complexInput.copy (tmp, null);
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
}
