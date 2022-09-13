"""
This downloads all templateflow templates, bc there's a problem with fmriprep not triggering
the downloading correctly (v.20.1.3)

Set the TEMPLATEFLOW_HOME env variable before calling this script to point to a folder that you later
provide to singularityfmriprep with:
-B /path/to/folder:/opt/templateflow

execute below before calling this script:

pip install --upgrade --pre templateflow
export TEMPLATEFLOW_HOME=/path/to/folder
export TEMPLATEFLOW_USE_DATALAD=false
"""

import templateflow.api as tfapi

# these should be all templates ever needed
templates = ["MNI152Lin",
            "MNI152NLin6Asym" ,
            "MNI152NLin6Sym" ,
            "MNI152NLin2009cAsym" ,
            "MNI152NLin2009cSym" ,
            "MNIInfant" ,
            "MNIPediatricAsym" ,
            "NKI" ,
            "OASIS30ANTs" ,
            "PNC" ,
            "WHS"]

# download the templates:
for template in templates:
    tfapi.get(template)