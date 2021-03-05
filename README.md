# MIMoSA BIDS app
For information about MIMoSA itself, see its [GitHub page](https://github.com/avalcarcel9/mimosa).

Usage:
```
usage: run.py [-h]
              [--participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL ...]]
              [--session [SESSION]] [--t1_label [T1_LABEL]]
              [--flair_label [FLAIR_LABEL]] [--brainmask [BRAINMASK]]
              [--strip [{bet,mass,}]] [--n4] [--register] [--whitestripe]
              [--debug] [--skip_bids_validator] [-v]
              bids_dir output_dir {participant,group}

MIMoSA entrypoint script

positional arguments:
  bids_dir              The directory with the input dataset formatted
                        according to the BIDS standard.
  output_dir            The directory where the output files should be stored.
                        If you are running group level analysis this folder
                        should be prepopulated with the results of
                        theparticipant level analysis.
  {participant,group}   Level of the analysis that will be performed. Multiple
                        participant level analyses can be run independently
                        (in parallel) using the same output_dir.

optional arguments:
  -h, --help            show this help message and exit
  --participant_label PARTICIPANT_LABEL [PARTICIPANT_LABEL ...]
                        The label(s) of the participant(s) that should be
                        analyzed. The label corresponds to
                        sub-<participant_label> from the BIDS spec (so it does
                        not include "sub-"). If this parameter is not provided
                        all subjects should be analyzed. Multiple participants
                        can be specified with a space separated list.
  --session [SESSION]   Specific session to process
  --t1_label [T1_LABEL]
                        label of T1 image
  --flair_label [FLAIR_LABEL]
                        label of FLAIR image
  --brainmask [BRAINMASK]
                        Brain mask
  --strip [{bet,mass,}]
                        Skull strip inputs (can pick from 'bet', 'mass', or
                        empty string to imply input is already skull stripped)
  --n4                  Whether to N4 correct input
  --register            Whether to register to T1
  --whitestripe         Whether to run WhiteStripe
  --debug               Write out additional debug output
  --skip_bids_validator
                        Whether or not to perform BIDS dataset validation
  -v, --version         show program's version number and exit
```