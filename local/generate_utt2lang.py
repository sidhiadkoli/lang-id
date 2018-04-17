import sys
import os
import codecs

utt2lang = {}

'''
arabic: 1
mandarin: 2
english: 3
'''

default_lang = {}

for la in ["1", "2", "3"]:
    default_lang[la] = 0

fFile = sys.argv[1]
outdir = sys.argv[2]
with codecs.open(fFile, "rb") as fin:
    lines = fin.readlines()
    fin.close()        
    
    utt_dict = {}
    utt_len = {}
    for line in lines:
        line = str(line)
        line = line[2:-3]
        line = line.replace("<unk>", "")
        splits = (" ".join(line.strip().split(" "))).split(" ")
    
        if splits[0] not in utt_dict.keys():
            utt_dict[splits[0]] = dict(default_lang)
            utt_len[splits[0]] = 0
        
        if len(splits) < 2:
            # there are no utterences.
            continue
            
        utt_len[splits[0]] += len(splits) - 1

        for word in splits[1:]:
            if "\\x" in word:
                utt_dict[splits[0]]["1"] += 1
            elif word.isupper():
                utt_dict[splits[0]]["3"] += 1
            else:
                utt_dict[splits[0]]["2"] += 1

utt_list = sorted(utt_dict.keys())

with open(outdir + "/utt2lang", "w") as fout:
    for u in utt_list:
        lang = "3"
        if "ar_" in u[0:3]:
            lang = "1" 
        elif "ma_" in u[0:3]:
            lang = "2"

        freq = list(utt_dict[u].values())
        la = list(utt_dict[u].keys())
        max_lang = la[freq.index(max(freq))]

        count = len([1 for f in freq if f == max(freq)])

        if count == 1:
            lang = max_lang

        fout.write(u + " " + lang + "\n")

    fout.close()

