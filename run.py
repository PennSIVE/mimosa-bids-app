#!/usr/bin/env python3
import argparse
import os
import subprocess
from glob import glob

__version__ = open(os.path.join(os.path.dirname(os.path.realpath(__file__)),
                                'version')).read()


def run(command, env={}):
    merged_env = os.environ
    merged_env.update(env)
    process = subprocess.Popen(command, stdout=subprocess.PIPE,
                               stderr=subprocess.STDOUT, shell=True,
                               env=merged_env)
    while True:
        line = process.stdout.readline()
        line = str(line, 'utf-8')[:-1]
        print(line)
        if line == '' and process.poll() != None:
            break
    if process.returncode != 0:
        raise Exception("Non zero return code: %d" % process.returncode)


parser = argparse.ArgumentParser(
    description='Example BIDS App entrypoint script.')
parser.add_argument('bids_dir', help='The directory with the input dataset '
                    'formatted according to the BIDS standard.')
parser.add_argument('output_dir', help='The directory where the output files '
                    'should be stored. If you are running group level analysis '
                    'this folder should be prepopulated with the results of the'
                    'participant level analysis.')
parser.add_argument('analysis_level', help='Level of the analysis that will be performed. '
                    'Multiple participant level analyses can be run independently '
                    '(in parallel) using the same output_dir.',
                    choices=['participant', 'group'])
parser.add_argument('--participant_label', help='The label(s) of the participant(s) that should be analyzed. The label '
                   'corresponds to sub-<participant_label> from the BIDS spec '
                   '(so it does not include "sub-"). If this parameter is not '
                   'provided all subjects should be analyzed. Multiple '
                   'participants can be specified with a space separated list.',
                   nargs="+")
parser.add_argument('--t1_label', help="label of T1 image", nargs='?', default="T1w")
parser.add_argument('--flair_label', help="label of FLAIR image", nargs='?', default="FLAIR")
parser.add_argument('--debug', help='Write out additional debug output', action='store_true')
parser.add_argument('--skip_bids_validator', help='Whether or not to perform BIDS dataset validation',
                   action='store_true')
parser.add_argument('-v', '--version', action='version',
                    version='BIDS-App example version {}'.format(__version__))


args = parser.parse_args()

if not args.skip_bids_validator:
    run('bids-validator %s' % args.bids_dir)

subjects_to_analyze = []
# only for a subset of subjects
if args.participant_label:
    subjects_to_analyze = args.participant_label
# for all subjects
else:
    subject_dirs = glob(os.path.join(args.bids_dir, "sub-*"))
    subjects_to_analyze = [subject_dir.split(
        "-")[-1] for subject_dir in subject_dirs]

# running participant level
if args.analysis_level == "participant":

    for subject_label in subjects_to_analyze:
        # just grab the first t1/flair
        t1 = (
            glob(os.path.join(args.bids_dir, "sub-%s" % subject_label, "anat", "*_%s.nii*" % args.t1_label)) +
            glob(os.path.join(args.bids_dir, "sub-%s" %
                 subject_label, "ses-*", "anat", "*_%s.nii*" % args.t1_label))
            )[0]
        flair = (
            glob(os.path.join(args.bids_dir, "sub-%s" % subject_label, "anat", "*_%s.nii*" % args.flair_label)) +
            glob(os.path.join(args.bids_dir, "sub-%s" %
                 subject_label, "ses-*", "anat", "*_%s.nii*" % args.flair_label))
            )[0]
        out_file = os.path.split(t1)[-1].replace("_%s." % args.t1_label, "_mimosa.")
        print("Reading from %s, writing to %s" % (args.output_dir, os.path.dirname(t1)))
        cmd = "/run.R --outdir %s --indir %s --flair %s --t1 %s" % (args.output_dir, os.path.dirname(t1), os.path.basename(flair), os.path.basename(t1))
        if args.debug:
            cmd += " --debug"
        run(cmd)