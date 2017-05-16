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



def read_mlf(MLF_path, MFCC_path, sampPeriod=100000):
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
    kaldi_one_best = open('lucas_1b_training.post', 'w')
    
    num_frames = 0
    total_num_frames = 0
    HEADER = 0
    MLFDEF = 1
    TRANSCRIPTION = 2
    retval = {}
    with open(MLF_path, 'r') as f:
        transcription = []
        state  = HEADER
        name = None
        prev_state = None
        for lineno, line in enumerate(f):
            line = line.strip()

            tokens = line.split()
            if len(tokens) == 0:
                continue

            if state == HEADER:
                if not line == '#!MLF!#':
                    raise ValueError('Invalid MLF header')
                else:
                    state = MLFDEF
            elif state == MLFDEF:
                tokens = line.split()
                if len(tokens) == 1:
                    name = tokens[0]
                    name = name.replace('"', '')
                    name = os.path.basename(name)
                    name, ext = os.path.splitext(name)
                    kaldi_one_best.write(name)
                    state = TRANSCRIPTION
                    transcription = []
                    continue
                elif len(tokens) == 3:
                    raise ValueError('Search in subdirectory defined in MLF '
                        'is not supported.')
                else:
                    raise ValueError('Invalid MLF definition.')
            elif state == TRANSCRIPTION:
                if line != '.':
                    line = line.strip()
                    if line == '///':
                        raise NotImplementedError('Unsupported: multiple segmentation in ' 
                        'HTK label files.')
                    # Discard empty line 
                    if len(tokens) == 0:
                        continue
                    tokens = line.split()
                    for frame in range(int(int(tokens[1])/sampPeriod - int(tokens[0])/sampPeriod)):
                        #if tokens[2][1].isalpha:
                        #    label = str(PHONES.index(tokens[2]))
                        #else:
                        label = tokens[2][1:]
                        kaldi_one_best.write(' [ ' + label + ' 1 ]')
                    num_frames = num_frames + int(int(tokens[1])/sampPeriod - int(tokens[0])/sampPeriod)    
                    #prev_state = tokens[2][1:]
                    prev_state = label
                else:
                    kaldi_one_best.write(' [ ' + prev_state  + ' 1 ]')
                    num_frames = num_frames + 1
                    if (MFCC_num_frames(name, MFCC_path) != (num_frames)):
                        print("mfcc length: " + str(MFCC_num_Frames(name, MFCC_path) + ", posterior length: " +str(num_frames)))
                    total_num_frames = total_num_frames + num_frames 
                    state = MLFDEF
                    kaldi_one_best.write('\n')
                    num_frames = 0
    return total_num_frames 

def main():
    # Command line parsing.
    #-----------------------------------------------------------------------
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('AUD_mlf', help='AUD MLF')
    parser.add_argument('path_to_mfcc', help='Path to the MFCCs (as .htk) of the utterances in the MLF')
    args = parser.parse_args()

    # Load the MLFs.
    #-----------------------------------------------------------------------
    total_num_frames = read_mlf(args.AUD_mlf, args.path_to_mfcc)
    print(total_num_frames)

if __name__ == '__main__':
    main()
else:
    raise ImportError('this script cannot be imported')
