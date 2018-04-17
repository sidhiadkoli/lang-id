# Script that converted the original Mandarin transcripts to the format: 
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
    for file in os.listdir(d + "/stm"):
        fName = os.fsdecode(file)
        if "ma_" not in fName:
            continue

        with open(d + "/stm/" + file) as fin2, open(d + "/stm_new/" + file, "w") as fout2:
            for line in fin2:
                if len(line.strip()) < 1:
                    continue
                fout2.write(utt[uc] + " " + utt2fName[utt[uc]] + " " + utt2spk[utt[uc]] + " " +
                    times[utt[uc]] + " " + " ".join(line.strip().split(" ")[3:]) + "\n")
                uc += 1
            fin2.close()
            fout2.close()

