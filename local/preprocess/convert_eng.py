# Convert TED-LIUM's english text to upper case.

import os, sys

#files = ["dev/text", "train/text", "test/text", "wordlist", "dev/stm", "test/stm", "local/dict/lexicon.txt"]
#files = ["../../db/train.txt", "../../db/english/train.txt"]

#files = ["train/stm_1", "dev/stm", "test/stm"]

files = sys.argv[1:]

for f in files:
    with open(f, "r") as fin, open(f + "_tmp", "w") as fout:
        if "text" in f:
            for lines in fin:
                splits = lines.strip().split(" ")
                for i in range(1, len(splits)):
                    splits[i] = splits[i].upper()
                fout.write(" ".join(splits) + "\n")
        elif "lexicon" in f:
            for lines in fin:
                splits = lines.strip().split(" ")
                splits[0] = splits[0].upper()
                fout.write(" ".join(splits) + "\n")
            
        elif "stm" in f:
            for lines in fin:
                if ";;" in lines or "ignore_time_segment_" in lines:
                    fout.write(lines)
                else:
                    splits = lines.strip().split(" ")
                    for i in range(6, len(splits)):
                        splits[i] = splits[i].upper()
                    fout.write(" ".join(splits) + "\n")
        else:
            for lines in fin:
                splits = lines.strip().split(" ")
                for i in range(len(splits)):
                    splits[i] = splits[i].upper()
                fout.write(" ".join(splits) + "\n")
        fin.close()
        fout.close()
    os.rename(f + "_tmp", f)
