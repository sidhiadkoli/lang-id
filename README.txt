Project: Spoken Language identification
UNI: sa3505
Name: Sidhi Adkoli
Course: Fundamentals of Speech Recognition COMS 6998 007

Data:

The cleaned speech data along with its formatted transcripts is present in folder sa3505_data
This folder contains the following structure:

arabic -----> dev ----> sph
		  ----> stm
		  ----> dev.txt 
	----> test ---> sph 
		   ---> stm
		   ---> test.txt
	----> train --> sph
		    --> stm
		    --> train.txt
	----> wordlist
	----> word_dict

english ----> dev ----> sph
		  ----> stm 
	----> test ---> sph 
		   ---> stm
	----> train --> sph
		    --> stm
	----> wordlist
	----> word_dict

mandarin ---> dev ----> sph
		  ----> stm 
	----> test ---> sph 
		   ---> stm
	----> train --> sph
		    --> stm
	----> wordlist
	----> word_dict

Where the folders and files are:
1. sph: Folder containing audio files. English and mandarin are in sph format while arabic is in wav format.
2. stm: Folder containing cleaned and formatted transcript files. English transcripts are in stm format. 
	Mandarin and arabic are txt files. The columns represent (separated by space):
		utt_id file_id speaker_id start_time end_time list_of_words...
3. dev, test, train: folders containing dev, test, and train data respectively.
4. wordlist: This file contains all words in the vocabulary.
5. word_dict: This file contains all words and their phones separated by spaces.
6. dev.txt, train.txt, test.txt: Arabic folder contains three files with the all their respective data set's text merged to a single file. This additional set of files is only for Arabic. This is because, the large number of stm files causes shell's cat function to spew out errors.

---------------------------

How to run:

1. Place the code folder lang_id in the egs folder of Kaldi. My scripts internally use kaldi scripts present in other folders, thus, maintaining this relative path is essential.
2. The data folder (sa3505_data) is present in lang_id/db folder. If this was in zipped form, then the run.sh script would have unzipped it automatically.
3. Execute run.sh. There are no other changes necessary. The "run" script performs all steps from data extraction till NN training without any further manual intervention.
4. The results are output to score.txt. This prints the lowest error rate achieved from that decode step. More detailed scores will be present in exp/tri{*}/decode_dev. 

Additional steps:
5. Since this project also converts speech to text, that accuracy can also be calculated. To do so, the following needs to be run: 
	$KALDI_ROOT/src/bin/compute-wer --mode=present --text ark:<hypothesis_text> ark:<reference_text>	
	eg: $KALDI_ROOT/src/bin/compute-wer --mode=present --text ark:exp/tri3/decode_dev.si/text data/dev/text
   This will output word-error-rates to stdout.
   The hypothesis text files are computed as a part of the run.sh workflow, so they will always be present in the decode directory if decode was successful.

----------------------------

Code changes:

For this project, several kaldi (and TED-LIUM) scripts were used as is, some were modified for this problem statement, and a few new scripts were added.

Modified scripts:
1. run.sh: This is based on TED-LIUM's run.sh with unnecessary steps commented out and invoking custom scripts in other places.
2. prepare_data.sh: Since the data is segregated into arabic, english and mandarin, they need to be both processed separately and combined into a single folder structure. This allows language models to be generated per language as well although for this project only the combined language model is used.
	The necessary files are generated in data/ folder.
3. prepare_dict.sh: This had a minor modification that took the dictionary and word-list files from data/ folder rather than db/.
4. ted_train_lm.sh: This trains the combined language model. Since the data is sorted per language, to ensure a good language model, the data needs to be shuffled so that all three languages are uniformly considered when generating the model.
5. utils/validate_dict_dir.pl, utils/validate_lang.pl, utils/validate_text.pl: English and mandarin transcripts lie in the range 64 to 122 ASCII range. However, to prevent conflicts, arabic data was shifted beyond this range to 130 to 187. This caused some text validation functions to fail. Those methods were modified to accommodate arabic text.
6. utils/scoring/wer_ops_details.pl, utils/scoring/wer_per_utt_details.pl: Since arabic data was shifted beyond 128 byte ASCII range, some of those characters could lead to issues when parsing and scoring. Thus, modifications were made to these files to interpret the text data as byte streams to avoid any issues.

New scripts:
1. Text conversion scripts (convert_mandarin.py, convert_arabic.py, convert_english.py): These scripts were written to run on the original transcript files. Those files needed to be cleaned modified. 
	a. Arabic: The arabic text was converted from UTF-8 arabic format to Buckwalter's romanized form. This was further lifted to the ASCII range 130 to 187 to not interfere with english and mandarin.
	b. English: All english transcripts were converted to upper-case to not interfere with pinyin (see c).
	c. Mandarin: The text in chinese script was converted to pinyin format. The pinyin text was entirely in lower case.
   These scripts are not invoked from any where and are kept as a note on how the text conversion was performed.
2. Audio conversion scripts: 
	a. Arabic: The audio files were in wav and were retained in this format. A script was written to extract the duration of the audio files.
	b. Mandarin (preprocess_sph.sh) : The audio files were in compressed sph format. Moreover, they were sampled at 8KHz. A script was written to uncompress the sph files, up-sample the audio, reduce the number of channels and convert the result to regular sph format.
3. Scoring: 
	a. score.sh : Extracts textual results from the decode folder into a single text file. It internally invokes get_lang_score.py that performs the actual scoring.




