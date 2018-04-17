# Script that converted the original arabic transcripts to the format: 
# <utt_id> <file_id> <speaker_id> <segments_start_end> [words]...

import sys, os

dirs = ["train", "dev", "test"]

for d in dirs:
    segments = []
    utt = []
    utt2fName = {}
    times = {}
    utt2spk = {}

    with open(d + "/segments", "r") as fin:
        segments = fin.read()
        fin.close()

    segments = segments.strip().split("\n")

    for s in segments:
        splits = s.strip().split(" ")
        utt.append(splits[0])
        utt2fName[splits[0]] = splits[1]
        times[splits[0]] = " ".join([splits[-2], splits[-1]])

    with open(d + "/utt2spk", "r") as fin:
        speakers = fin.read()
        fin.close()

    speakers = speakers.strip().split("\n")
    for s in speakers:
        splits = s.strip().split(" ")
        utt2spk[splits[0]] = splits[1]

    uc = 0
    for u in utt:
        with open(d + "/tmp/" + u + ".txt", "w") as fout2:
            fout2.write(u + " " + utt2fName[u] + " " + utt2spk[u] + " " +
                times[u] + "\n")
            fout2.close()

