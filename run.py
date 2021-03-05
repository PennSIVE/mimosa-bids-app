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
    description='MIMoSA entrypoint script')
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
parser.add_argument('--session', help="Specific session to process", nargs='?', default = "*")
parser.add_argument('--t1_label', help="label of T1 image", nargs='?', default="T1w")
parser.add_argument('--flair_label', help="label of FLAIR image", nargs='?', default="FLAIR")
parser.add_argument('--brainmask', help = "Brain mask", nargs='?', default = False)
parser.add_argument('--strip', help = "Skull strip inputs (can pick from 'bet', 'mass', or empty string to imply input is already skull stripped)", nargs = '?', choices = ['bet', 'mass', ''], default = '')
parser.add_argument('--n4', help = "Whether to N4 correct input", action='store_true')
parser.add_argument('--register', help = "Whether to register to T1", action='store_true')
parser.add_argument('--whitestripe', help = "Whether to run WhiteStripe", action='store_true')
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
        t1 = sorted((
            glob(os.path.join(args.bids_dir, "sub-%s" % subject_label, "anat", "*_%s.nii*" % args.t1_label)) +
            glob(os.path.join(args.bids_dir, "sub-%s" %
                 subject_label, "ses-%s" % (args.session), "anat", "*_%s.nii*" % args.t1_label))
            ))
        flair = sorted((
            glob(os.path.join(args.bids_dir, "sub-%s" % subject_label, "anat", "*_%s.nii*" % args.flair_label)) +
            glob(os.path.join(args.bids_dir, "sub-%s" %
                 subject_label, "ses-%s" % (args.session), "anat", "*_%s.nii*" % args.flair_label))
            ))

        n = len(t1)
        m = len(flair)
        if n != m:
            raise ValueError("Not sure which %s images to pair with which %s images since there are different numbers (%d vs %d)" % (
                args.t1_label, args.flair_label, n, m))
        for i in range(n):
            out_file = os.path.split(t1[i])[-1].replace("_%s." % args.t1_label, "_mimosa.")
            print("Reading from %s, writing to %s" % (args.output_dir, os.path.dirname(t1[i])))
            cmd = "/run.R --outdir %s --indir %s --flair %s --t1 %s --strip %s" % (args.output_dir, os.path.dirname(t1[i]), os.path.basename(flair[i]), os.path.basename(t1[i]), args.strip)
            if args.debug:
                cmd += " --debug"
            if args.brainmask:
                cmd += " --brainmask %s" % args.brainmask
            if args.n4:
                cmd += " --n4"
            if args.register:
                cmd += " --register"
            if args.whitestripe:
                cmd += " --whitestripe"
            run(cmd)
