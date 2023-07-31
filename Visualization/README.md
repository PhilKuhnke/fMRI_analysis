# Visualization of fMRI results

## Whole-brain statistical maps
The result of a typical whole-brain fMRI analysis (e.g. mass-univariate activation mapping) is a statistical parametric map (SPM) 
that is thresholded at an appropriate statistical threshold (e.g. p < 0.05 FWE-corrected) --> See [Second-Level Analysis](https://gitlab.gwdg.de/cognition-and-plasticity-cbs-mpi/copla-internals/-/tree/master/code/fMRI_analysis/Second_level_analysis). 

Such a map can be visualized using a variety of ways,
including slices, 3D renders, and surface projection.

### Slices
fMRI maps can be plotted on anatomical slices of the brain. 
Programs include:
- [mricron](https://www.nitrc.org/projects/mricron)
- [mricrogl](https://www.nitrc.org/projects/mricrogl)
- [Mango](https://mangoviewer.com/)
- [fsleyes](https://fsl.fmrib.ox.ac.uk/fsl/fslwiki/FSLeyes)

It is often reasonable to show both sides of a contrast (i.e. positive & negative activations).

Use reasonable colormaps (e.g. activations = warm colors; red -> yellow, deactivations = cool colors; blue -> green). Also, add colorbars to your figure (what do the different colors mean?)

### 3D Renders
As fMRI maps are 3D, they can also be displayed as 3D volumetric renderings. 
Programs include:
- [mricrogl](https://www.nitrc.org/projects/mricrogl)

The overlay transparency can be increased to show deeper activity clusters. Moreover, it is often possible to "cut" into the brain to show deeper structures (e.g. a medial cut).

### Glass Brain
Glass brain renderings let you "see through" the brain to reveal all activations at once. 
Programs include:
- [mricrogl](https://www.nitrc.org/projects/mricrogl)
- [nilearn (Python)](https://nilearn.github.io/dev/plotting/index.html)

### Surface Projections
Surface projections interpolate the activity clusters to the cortical surface. This is often the clearest form of visualization and therefore my personal preference. 
Programs include:
- [mni2fs (Matlab)](https://gitlab.gwdg.de/cognition-and-plasticity-cbs-mpi/copla-internals/-/blob/master/code/fMRI_analysis/Visualization/mni2fs.zip)
- [nilearn (Python)](https://nilearn.github.io/dev/plotting/index.html)
- [pycortex (Python)](https://github.com/gallantlab/pycortex)
- [BrainNet Viewer (Matlab)](https://www.nitrc.org/projects/bnv/)





