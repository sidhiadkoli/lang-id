# Convert Mandarin text to pinyin.

import codecs
import re
import sys
import os

dir = "./"
unk = "<unk>"

lex = {}

with codecs.open(dir + "lexicon_without_tone.txt", 'rb') as fin:
    for line in fin:
        line = str(line).replace("b\'", "").replace("\'", "").replace("\\n", "").replace("\\t", "\t")
        splits = line.strip().split("\t")
        lex[splits[0]] = splits[1]

for folder in sys.argv[1:]:
    for file in os.listdir(folder):
        fName = os.fsdecode(file)
        if "ma_" not in fName:
            continue
        with codecs.open(folder + "/" + file, 'rb') as fin, codecs.open(folder + "_processed/" + fName, 'w') as fout:
            for line in fin:
                line = str(line).replace("b\'", "").replace("\'", "").replace("\\n", "").replace("b\"", "").replace("\"", "")
                line = line.replace("((", "").replace("))", "").replace("&", "").replace("+", "").replace("%", "").replace("@", "")
                line = line.replace("#", "").replace("//", "")
                line = line.replace("-", "").replace(",", "").replace("?", "").replace("!", "")
                line = line[:14] + line[14:].replace(".", "")

                while ("[[" in line):
                    line = re.sub(r'\[\[[\w\d\_\\\S]*\]\]', '', line)

                while ("[" in line):
                    line = re.sub(r'\[[\w\d\_\\\/,\S]*\]', '', line)

                while ("{" in line):
                    line = re.sub(r'\{[\/\w\d\_\\\S]*\}', '', line)

                splits = line.strip().split(" ")

                for s in splits:
                    if (s == ""):
                        continue

                    if "<English_" in s:
                        s1 = s.replace("<", "").replace(">", "")

                        parts = s1.split("_")
                        parts = parts[1:]
                        
                        for p in parts:
                            if len(p) > 0:
                                # print(p)
                                fout.write(p.upper() + " ")
                        continue

                    if (len(s) > 2 and s[-1] == "-"):
                        s = s[:len(s) - 1]
                    if (len(s) > 2 and s[0] == "-"):
                        s = s[1:]

                    if (s in lex.keys()):
                        fout.write(lex[s] + " ")
                    else:
                        # If it's a hex number, then the pinyin form for it was not found.
                        # Write <unk> instead.
                        # Else, write the word as is.
                        if ("\\x" in s):
                            fout.write(unk + " ")
                        else:
                            fout.write(s + " ")
                fout.write("\n")
            fin.close()

