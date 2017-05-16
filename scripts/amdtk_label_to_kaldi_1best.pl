#!/usr/bin/perl

import argparse
import os
import amdtk
from amdtk.core import readTimitLabels
from amdtk.core import readHtkLabels
from amdtk.core import writeMlf

PHONES = ['#h', 'aa', 'ae', 'ah', 'ao', 'aw', 'ax', 'ax-h', 'axr', 'ay', 'b',
          'bcl', 'ch', 'd', 'dcl', 'dh', 'dx', 'eh', 'el', 'em', 'en', 'eng',
          'epi', 'er', 'ey', 'f', 'g', 'gcl', 'h#', 'hh', 'hv', 'ih', 'ix',
          'iy', 'jh', 'k', 'kcl', 'l', 'm', 'n', 'ng', 'nx', 'ow', 'oy', 'p',
          'pau', 'pcl', 'q', 'qcl', 'r', 's', 'sh', 't', 'tcl', 'th', 'uh', 'uw',
          'ux', 'v', 'w', 'y', 'z', 'zh']

def MFCC_num_frames(name, MFCC_path):
    feature_file = name + ".fea"
    mfccs = amdtk.readHtk(MFCC_path + feature_file)
    return mfccs.shape[0]



def read_mlf(Label, Kaldi_1best, name,MFCC_path, sampPeriod=100000):
    '''Read a Master Label File.

    Read a Master Label File (MLF) as defined 
    `here <http://www.ee.columbia.edu/ln/LabROSA/doc/HTKBook21/node86.html>`_.
    Only the immediate transcription is supported.
    
    Parameters
    ----------
    path : str
        Path to the file.
    sampPeriod : int
        The sampling period in 100ns (default is 1e5).
    '''
    #kaldi_one_best = open('lucas_1b_training.post', 'w')
    

    num_frames = 0
    total_num_frames = 0
    retval = {}

    with open(Label, 'r') as f:
	    for lineno, line in enumerate(f):
		    line = line.strip()
		    tokens = line.split()
		    if len(tokens) != 3:
			    raise ValueError('Invalid MLF')
		    else:
			    for frame in range(int(int(tokens[1])/sampPeriod - int(tokens[0])/sampPeriod)):
				    label = tokens[2][1:]
				    Kaldi_1best.write(' [ ' + label + ' 1 ]')
				    num_frames = num_frames + int(int(tokens[1])/sampPeriod - int(tokens[0])/sampPeriod)
		    if (MFCC_num_frames(name,MFCC_path) != (num_frames)):
			    print("mfcc length: " + str(MFCC_num_Frames(name, MFCC_path) + ", posterior length: " +str(num_frames)))
			    total_num_frames = total_num_frames + num_frames
			    Kaldi_1best.write('\n')
    return total_num_frames 

def main():
    # Command line parsing.
    #-----------------------------------------------------------------------
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('htk_label', help='AUD label file, *.lab')
    parser.add_argument('kaldi_1best', help='Kaldi format 1best posts file, *.post')
    parser.add_argument('mfcc_path',help='MFCC path with *.htk file to check frames')
    args = parser.parse_args()
    
    name=os.path.splitext(os.path.basename(args.htk_label))[0]
    k1best= open(args.kaldi_1best,'w')
    k1best.write(name)

    # Load the MLFs.
    #-----------------------------------------------------------------------
    total_num_frames = read_mlf(args.htk_label,k1best,name,args.mfcc_path)
    print(total_num_frames)

if __name__ == '__main__':
    main()
else:
    raise ImportError('this script cannot be imported')
