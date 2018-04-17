# Create wav.scp
import sys

for folder in sys.argv[2:]:
    with open(folder + "/segments", "r") as fin, open(folder + "/wav.scp", "w") as fout:
        fname = []
        for line in fin:
            fname.append(line.split(" ")[1])

        fname = set(fname)
        fname = sorted(list(fname))

        for f in fname:
            fout.write(f + " sph2pipe -f wav -p " + sys.argv[1] + "/" + f + ".sph |\n")
        fout.close()
        fin.close()
