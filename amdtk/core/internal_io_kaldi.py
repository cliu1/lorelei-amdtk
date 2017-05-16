"""
Functions for dealing with data input and output.

adapt from 
Date: 2016
"""

from os import path
import gzip
import logging
import numpy as np
import struct


#-----------------------------------------------------------------------------#
#                            GENERAL I/O FUNCTIONS                            #
#-----------------------------------------------------------------------------#

def __smart_open(filename, mode=None):
  """Opens a file normally or using gzip based on the extension."""
  if path.splitext(filename)[-1] == ".gz":
    if mode is None:
      mode = "rb"
    return gzip.open(filename, mode)
  else:
    if mode is None:
      mode = "r"
    return open(filename, mode)


#def read_kaldi_ark_from_scp(scp_fn, ark_base_dir=""):
def readKaldi(scp_fn, infos=False):
  """
  Read a binary Kaldi archive and return a dict of Numpy matrices, with the
  utterance IDs of the SCP as keys. Based on the code:
  https://github.com/yajiemiao/pdnn/blob/master/io_func/kaldi_feat.py

  Parameters
  ----------
  ark_base_dir : str
      The base directory for the archives to which the SCP points.
  """

  ark_dict = {}
  ark_base_dir=""
  nSamples=0
  sampPeriod=100000
  sampSize=0

  with open(scp_fn) as f:
    for line in f:
      if line == "":
        continue
      utt_id, path_pos = line.replace("\n", "").split(" ")
      ark_path, pos = path_pos.split(":")

      ark_path = path.join(ark_base_dir, ark_path)

      ark_read_buffer = __smart_open(ark_path, "rb")
      ark_read_buffer.seek(int(pos),0)
      header = struct.unpack("<xcccc", ark_read_buffer.read(5))
      #assert header[0] == "B", "Input .ark file is not binary"
      assert header[0] == b'B', "Input .ark file is not binary"

      rows = 0
      cols= 0
      m, rows = struct.unpack("<bi", ark_read_buffer.read(5))
      n, cols = struct.unpack("<bi", ark_read_buffer.read(5))

      tmp_mat = np.frombuffer(ark_read_buffer.read(rows*cols*4), dtype=np.float32)
      utt_mat = np.reshape(tmp_mat, (rows, cols))

      ark_read_buffer.close()

      ark_dict[utt_id] = utt_mat
      if not infos:
        return utt_mat
      return utt_mat, (nSamples, sampPeriod, sampSize)

  #return ark_dict

def readKaldi_scp(scp_line, infos=False):
  """
  Parameters
  ----------
  """

  ark_dict = {}
  ark_base_dir=""
  nSamples=0
  sampPeriod=100000
  sampSize=0

  #
  utt_id, path_pos = scp_line.replace("\n", "").split(" ")
  ark_path, pos = path_pos.split(":")

  ark_path = path.join(ark_base_dir, ark_path)

  ark_read_buffer = __smart_open(ark_path, "rb")
  ark_read_buffer.seek(int(pos),0)
  header = struct.unpack("<xcccc", ark_read_buffer.read(5))
  #assert header[0] == "B", "Input .ark file is not binary"
  assert header[0] == b'B', "Input .ark file is not binary"

  rows = 0
  cols= 0
  m, rows = struct.unpack("<bi", ark_read_buffer.read(5))
  n, cols = struct.unpack("<bi", ark_read_buffer.read(5))

  tmp_mat = np.frombuffer(ark_read_buffer.read(rows*cols*4), dtype=np.float32)
  utt_mat = np.reshape(tmp_mat, (rows, cols))

  ark_read_buffer.close()

  ark_dict[utt_id] = utt_mat
  if not infos:
    return utt_mat
  return utt_mat, (nSamples, sampPeriod, sampSize)

