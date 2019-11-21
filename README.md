# SAMIRIX
SAMIRIX is a custom-developed intraretinal segmentation pipeline. It modularly includes import filters for OCT data, a 3rd-party segmentation algorithm, a user interface for controlling and correcting segmentation results, and batch-operations for processing multiple OCT images.

Currently, it is written in a way to work with OCTLayerSegmentation, which has been released as a package of AURA Tools on NITRC (<https://www.nitrc.org/projects/aura_tools/>), as the third party segmentation algorithm (OCTLayerSegmentation source code is not included).

This software was introduced and described in details in a paper **Normative data and minimally detectable change for inner retinal layer thicknesses using a semi-automated OCT image segmentation pipeline**, Motamedi et al. ([Translational Neuroimaging Group (DIAL)](http://neurodial.de/), Charité Universitätsmedizin Berlin).

The updated version of SAMIRIX has three main changes in comparison to the one described in the Normative Data paper.

1. SAMIRIX is now able to segment macular OCT volumes from Zeiss Cirrus (.img files) and Topcon (.fda files) OCT devices. Segmented volumes from these devices are stored in .bin file format, which can be read and edited by SAMIRIX.
2. There is a new thickness export mode: 1- to 5-mm doughnut. The thickness inside an annulus centered on the fovea with inner diameter of 1 mm and outer diameter of 5 mm is exported in this mode. Additionally, in this mode, the fovea is once again located, but this time based on the inner limiting membrane (ILM) and Bruch's membrane (BM) segmented by SAMIRIX (and manually corrected). In this mode, a thickness value is not reported if the segmentation line or the volume is partly missing within the annulus (the thickness is till exported if the segmentation lines or volume is partly missing in other modes (similar to what Heidelberg Engineering Eye Explorer (HEYED) does), unless the missing part is larger than one sector).
3. The center (fovea) can now be in the middle of two adjacent B-scans and/or A-scans. In the previous version, the center had to be always on one of the B-scans and A-scans. In this version, the center is located on a degree 4 polynomial, fitted to the flattened ILM surface based on BM.
4. A "Segment Selected" button has been added to GUI, so there is no need to segment all the volumes in a folder, instead one can select one or some of the volumes and SAMIRIX only segments the selected volume(s). 

## Installation
In order to run SAMIRIX, MATLAB v2016b or later with Curve Fitting toolbox installed on a Windows PC is needed. Additionally, in order to use SAMIRIX with all its features, the software below should be downloaded and placed in the "Samirix" directory:

1. OCTLayerSegmentation2.11 (<https://www.nitrc.org/frs/?group_id=905>)
2. OCT-Marker (octmarker64 <https://github.com/neurodial/OCT-Marker/releases>)

After placing "octmarker64" and "OCTLayerSegmentation2.11" folders in the "Samirix" folder, the main folder (the folder which contains the LICENSE.txt and README file) and all its subfolders have to added to MATLAB Path (by right clicking on the main folder in the Current Folder layout in MATLAB and selecting Add to Path > Selected Folders and Subfolders).

## Usage
You can run SAMIRIX by typing "Samirix_GUI" and pressing Enter in Command Window or by openning "Samirix_GUI.m" and pressing the Run Button (or F5).

In order to understand how SAMIRIX functions, please read the sections describing SAMIRIX in the paper.

Please note that it is a common mistake to open Samirix_GUI.fig instead of opening and running Samirix_GUI.m, which should be avoided.

## Contact
Please contact Dr. Alexander U. Brandt (alexander.brandt@charite.de) for any inquires about this software.

## License
Please read LICENSE.txt.
