#!/bin/bash

# Copyright 2012 Vassil Panayotov
# Apache 2.0

# Note: you have to do 'make ext' in ../../../src/ before running this.

# Set the paths to the binaries and scripts needed
KALDI_ROOT=`pwd`/../../..
export PATH=$PWD/../s5/utils/:$KALDI_ROOT/src/onlinebin:$KALDI_ROOT/src/bin:$PATH

data_file="online-data"
data_url="http://sourceforge.net/projects/kaldi/files/online-data.tar.bz2"

# Change this to "tri2a" if you like to test using a ML-trained model
ac_model_type=tri4a

# Alignments and decoding results are saved in this directory(simulated decoding only)
decode_dir="./work"

# Change this to "live" either here or using command line switch like:
# --test-mode live
test_mode="live"

#. parse_options.sh

#ac_model=${data_file}/models/$ac_model_type
ac_model=exp/tri4a
trans_matrix=""
audio=${data_file}/audio
. ./cmd.sh
#if [ ! -s ${data_file}.tar.bz2 ]; then
#    echo "Downloading test models and data ..."
#    wget -T 10 -t 3 $data_url;
#
#    if [ ! -s ${data_file}.tar.bz2 ]; then
#        echo "Download of $data_file has failed!"
#        exit 1
#    fi
#fi

#if [ ! -d $ac_model ]; then
#    echo "Extracting the models and data ..."
#    tar xf ${data_file}.tar.bz2
#fi

#if [ -s $ac_model/matrix ]; then
#    trans_matrix=$ac_model/matrix
#fi

steps/online/prepare_online_decoding.sh --cmd "$train_cmd" data/train data/lang exp/tri4a \
		exp/tri4a/final.mdl exp/tri4a_online/ || exit 1;

   

# Estimate the error rate for the simulated decoding
if [ $test_mode == "simulated" ]; then
    # Convert the reference transcripts from symbols to word IDs
    sym2int.pl -f 2- $ac_model/words.txt < $audio/trans.txt > $decode_dir/ref.txt

    # Compact the hypotheses belonging to the same test utterance
    cat $decode_dir/trans.txt |\
        sed -e 's/^\(test[0-9]\+\)\([^ ]\+\)\(.*\)/\1 \3/' |\
        gawk '{key=$1; $1=""; arr[key]=arr[key] " " $0; } END { for (k in arr) { print k " " arr[k]} }' > $decode_dir/hyp.txt

   # Finally compute WER
   compute-wer --mode=present ark,t:$decode_dir/ref.txt ark,t:$decode_dir/hyp.txt
fi
