

## What is [fMRIprep](https://fmriprep.org/en/latest/index.html)?
some text here


## running fMRIprep
fMRIprep can only be [run](https://fmriprep.org/en/latest/singularity.html) on the institute's computeservers (and on your personal notebooks of course), and not on the workstations.
singularity (a docker-ish tool) is used to call the fMRIprep container.

### install fMRIprep container (only needed once)
```sh
getserver -ll     # show computeservers
ssh %SERVERNAME%  # connect to one computeserver

# now build fmriprep container direct from web
SINGULARITY_CACHEDIR=/tmp SINGULARITY_TMPDIR=/tmp singularity build /my_images/fmriprep-<version>.simg docker://poldracklab/fmriprep:<version>
# without the cachedir and tmdir settintg your home directory is flooded
```

get the newest version nr from [here](https://fmriprep.org/en/latest/index.html) and stick to that version for the whole analysis  
Currently (v20.1.3) there is a problem with  [templateflow](https://fmriprep.org/en/latest/singularity.html#templateflow-and-singularity), resulting in `empty files` errors for me (Ole). Piping templateflow and manually downloading everything as described [here](https://gist.github.com/FidgetteSpinneur/4f45af8862074fe0076dcd41faa4f80e) fixed this (see `download_templateflow_templates.py`). Do the same, ask me for the templateflow folder, or use 20.1.1.


### example fMRIprep call
 
 * call fmriprep container with parameters:
   * `-B /data/pt_01994`: allow access to `/data/pt_01994`
   * `-B /data/pt_01994/software/templateflow:/opt/templateflow`: provide templateflow data path (see above)
   * `/data/pt_01994/stimdmn/bids`: here the BIDS structured data sits
   * `participant`: for subject `01` 
   *  `--fs-license-file`: freesurfer license file is provided to allow freesurfer registration (?)
   * `--output-space`: with multiple MNI/FSL output spaces
   * `--nthreads`: run on 6 cpus
   * `-w` set working directory to `/data/pt_01994/stimdmn/fmriprep/wd`
```sh
export SINGULARITYENV_TEMPLATEFLOW_HOME=/opt/templateflow # direcory
singularity run -B /data/pt_01994 -B /data/pt_01994/software/templateflow:/opt/templateflow --cleanenv  /data/pt_01994/software/fmriprep-20.1.3.simg /data/pt_01994/stimdmn/bids    
   /data/pt_01994/stimdmn/fmriprep/output/ --fs-license-file /data/pt_01994/fmriprep/license.txt   
   participant --participant-label 01     
   --output-space T1w MNI152Lin MNI152NLin2009cAsym fsaverage --nthreads 6 -w /data/pt_01994/stimdmn/fmriprep/wd
```

Another xample call:  
```sh 
singularity run -B /data/pt_02287 -B /data/pt_02287/DYSL2020/fMRI_analysis/Scripts/fMRIprep/templateflow:/home/fmriprep/.cache/templateflow --cleanenv /data/pt_02287/DYSL2020/fMRI_analysis/Scripts/fMRIprep/fmriprep-20.2.1.simg /data/pt_02287/DYSL2020/fMRI_analysis/_BIDS_DYSL2020_CG/Nifti_TEST /data/pt_02287/DYSL2020/fMRI_analysis/fMRIprep/output --fs-license-file /data/pt_02287/DYSL2020/fMRI_analysis/Scripts/fMRIprep/license.txt participant --participant-label 13536 --output-space T1w MNI152Lin MNI152NLin2009cAsym fsaverage fsnative --nthreads 6 -w /data/pt_02287/DYSL2020/fMRI_analysis/fMRIprep/wd```
