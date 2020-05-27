# Detect Spindles EEGlab Plugin

Method for detecting sleep spindles using GUI in EEGlab for MATLAB

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes.

### Prerequisites

Mac, PC and Linux compatible.  
Designed for use with EEGlab 2019_1 on Matlab R2019a.  
For use on continuous eeglab datasets (*.set).  
Requires sleep scoring and movement artifacts to be included in EEG.event structure.

### Installing

Simply unzip and copy 'detect_spindles_plugin' to '~/eeglab/plugins/'

## Usage

There are two options:

1) using the eeglab interface:

* at the matlab command prompt, add eeglab root directory to the path and launch eeglab
* load an eeglab dataset
* navigate to Tools>Detect Spindles>Detect Spindles>

2) Customize and run 'detect_spindles_batch.m' to process multiple datasets.

## Authors

Stephane Sockeel, PhD, University of Montreal  
Stuart Fogel, PhD, University of Ottawa

## Contact 

sfogel@uottawa.ca  
http://socialsciences.uottawa.ca/sleep-lab/

## License

Copyright (C) Stuart Fogel & Stephane Sockeel, 2016, 2020.  
See the GNU General Public License for more details.

## Acknowledgments

Thanks to support from Julien Doyon and input from Arnaud Bore.

## Citation

Ray, L.B., Sockeel, S., Soon, M., Bore, A., Myhr, A., 
Stojanoski, B., Cusack, R., Owen, A.M., Doyon, J., Fogel, S., 
2015. Expert and crowd-sourced validation of an individualized 
sleep spindle detection method employing complex demodulation 
and individualized normalization. Front. Hum. Neurosci. 9. 

doi: 10.3389/fnhum.2015.00507

journal.frontiersin.org/article/10.3389/fnhum.2015.00507/full
