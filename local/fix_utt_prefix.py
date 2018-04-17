import sys

uttDict = {}

for folder in sys.argv[1:]:
    with open(folder + "/utt2spk", "r") as fin, open(folder + "/utt2spk_f", "w") as fout:
        for line in fin:
            splits = line.strip().split(" ")
            utt = splits[0]
            spk = splits[1]
            uttDict[utt] = spk + "-" + "_".join(utt.split("_")[2:])
            fout.write(uttDict[utt] + " " + spk + "\n");
        fin.close()
        fout.close()
    
    with open(folder + "/segments", "r") as fin, open(folder + "/segments_f", "w") as fout:
        for line in fin:
            splits = line.strip().split(" ")
            utt = uttDict[splits[0]]

            fout.write(utt + " " + " ".join(splits[1:]) + "\n")
        fin.close()
        fout.close()
    
    with open(folder + "/text", "r") as fin, open(folder + "/text_f", "w") as fout:
        for line in fin:
            splits = line.strip().split(" ")
            utt = uttDict[splits[0]]

            fout.write(utt + " " + " ".join(splits[1:]) + "\n")
        fin.close()
        fout.close()
