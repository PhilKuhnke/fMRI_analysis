"""
Implementation of the broken-stick model to select number of aCompCor components

Based on discussions here:
https://neurostars.org/t/fmriprep-outputs-very-high-number-of-acompcors-up-to-1000/5451/7
https://blogs.sas.com/content/iml/2017/08/02/retain-principal-components.html


For each mask ('CSF', 'WM', 'combined'), the number of components to select according to the broken stick approach is
computed.
For the broken stick model, the total number of extracted components is relevant. While this should be ~equal to the
number of TRs, this does not seem to be the case for the CSF components. It's therefore not clear to me (Ole) right now
what the correct baseline for the CSF mask is. Therefore, i would not use these, but pick components derived for either
the 'compbined' or the 'WM' mask.


fmriprep (nypipe really) computes all aCompCor components and only returns the ones needed to yield 50% explained
variance ('Retained') in the .tsv file. Meta information about all components are provided in the .yaml file, although
the ordering is a bit flawed. The .yaml file also stores information about other confounds, like global signal, etc.
"""

import os
import json
import numpy as np

fn = "/data/pt_02243/probands/sub98/mri/task_ses1/preproc/task1_confounds.json"

print(f"Calculating number of aCompCor components to keep for {fn}.\n")
print(f" {'mask': >8} n_comp_keep | n_comps_total | n_comps_retained | n_comps_dropped")
print("-"*80)
for mask in ['WM','combined','CSF',]:

    if not os.path.exists(fn):
        raise FileNotFoundError(f"Can\'t open {fn}. Quitting.")
    with open(fn, 'r') as f:
        data = json.load(f)

    res = []
    n_comps_total, n_comps_retained, n_comps_dropped = 0, 0, 0  # some counters

    # walk through all items in the json file
    for key, dat in data.items():
        try:
            # grab the aCompCor for the correct masks
            if dat['Method'] == 'aCompCor' and dat['Mask'] == mask:
                n_comps_total += 1

                # let's only grab the ones for which we also have the timeseries data
                if dat['Retained']:
                    res.append(key)
                    n_comps_retained +=1
                else:
                    n_comps_dropped +=1

        except KeyError:
            # just ignore the items that don't have 'Method' or Mask 'key'
            pass

    # the baseline expectation according to the broken stick model:
    # if n_comps == 3:
    #   exp_comp = [(1 + 1/2 + 1/3) / n_comps, (1/2 + 1/3) / n_comps, (1/3) / n_comps]
    exp_comp = list(reversed(np.cumsum(list(reversed(1 / np.array(list(range(1, n_comps_total + 1))))))
                             / n_comps_total))

    # get the retained keys in the correct order (was: 01,...09, 10, 100, 101, ...
    keys_sorted = list(sorted(res, key=lambda e: int(e.split('_')[-1])))

    # some checks here
    for i in range(len(keys_sorted) - 1):
        # print(f"{i:0>3}: {res[keys_sorted[i]]['VarianceExplained']:2.6f} "
        #       f"(cum: {res[keys_sorted[i]]['CumulativeVarianceExplained']:2.6f})")

        # if things work as I think, components should be ordered by there explained variance (highes first)
        assert data[keys_sorted[i]]['VarianceExplained'] >= data[keys_sorted[i + 1]]['VarianceExplained']

    # get the number of components to keep for this mask
    n_comp_keep = 0
    for i in range(0, len(keys_sorted)):
        if data[keys_sorted[i]]['VarianceExplained'] > exp_comp[i]:
            # uptick counter if variance explained of this component is larger than what the baseline predicts for
            # random data
            n_comp_keep += 1
        else:
            # otherwise quit this loop
            break

    # # you can use something like this to generate the compcor names
    # comp_keep_names = [keys_sorted[i] for i in range(n_comp_keep)]
    #
    # # ... and then subset the .tsv file with pandas
    # import pandas as pd
    # all_confounds = pd.read_csv(confounds_fn, sep="\t")
    # subset_confounds = all_confounds[comp_keep_names].copy()

    print(f" {mask: >8} {n_comp_keep: >11} | {n_comps_total: >13} | {n_comps_retained: >16} | {n_comps_dropped: >14}")
print("="*80)
