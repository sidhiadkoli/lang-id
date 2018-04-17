import sys
import os
import codecs

def get_lang(utt):
    if "ar_" in utt[0:3]:
        return "1"

    if "ma_" in utt[0:3]:
        return "2"

    return "3"

file_to_score = {}
utt2lang = {}
lang = []

'''
arabic: 1
mandarin: 2
english: 3
'''

final_folder = sys.argv[2].split("/")[:-1]
final_folder = "/".join(final_folder)

with open(sys.argv[1] + "/utt2lang" , "r") as utt2langFile:
    for line in utt2langFile:
        splits = line.strip().split(" ")
        utt2lang[splits[0]] = splits[1]
        lang.append(splits[1])
    utt2langFile.close()

lang = set(lang)
default_lang = {}
err_list = []

for la in lang:
    default_lang[la] = 0

for fFile in sys.argv[2:]:
    print(fFile)
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
            
        if "ctm" in fFile:
            if len(splits) != 6:
                continue
            # In the ctm file, we only need the 4th column value.
            splits = [splits[0], splits[4]]

        if len(splits) < 2:
            # there are no utterences.
            continue
            
        if splits[0] not in utt_dict.keys():
            utt_dict[splits[0]] = dict(default_lang)
            utt_len[splits[0]] = 0
            
        utt_len[splits[0]] += len(splits) - 1

        for word in splits[1:]:
            if "\\x" in word:
                utt_dict[splits[0]]["1"] += 1
            elif word.isupper():
                utt_dict[splits[0]]["3"] += 1
            else:
                utt_dict[splits[0]]["2"] += 1

    with open(final_folder + "/score.txt", "a+") as fout:
        err = 0
        lang_error = dict(default_lang)
        for k, v in utt_dict.items():
            if ((v["1"] == v["2"] and v["3"] < v["2"]) 
                or (v["2"] == v["3"] and v["1"] < v["2"])
                or (v["1"] == v["3"] and v["2"] < v["3"])):
                err += 1
                lang_error[get_lang(k)] += 1
                #print(k)
            else:
                freq = list(v.values())
                la = list(v.keys())
            
                max_lang = la[freq.index(max(freq))]
                #print(k, max_lang)

                if max_lang != utt2lang[k]:
                    err += 1
                    lang_error[get_lang(k)] += 1
                    #print(k)

        err2 = (err/len(utt_dict.keys())) * 100
        err_list.append(err2)
        fout.write(fFile + " " + str(err) + " " + str(err2) + "\n")
        fout.write("Arabic: " + str(lang_error["1"]) + "\n")
        fout.write("Mandarin: " + str(lang_error["2"]) + "\n")
        fout.write("English: " + str(lang_error["3"]) + "\n")
        fout.close()

with open("score.txt", "a+") as fout:
    print(min(err_list))
    fout.write(final_folder + " " + str(min(err_list)) + "\n")
    fout.close()

