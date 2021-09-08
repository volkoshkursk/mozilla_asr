#!/usr/bin/env bash
# echo "prepare dataset"
# python3 bin/import_cv2.py --audio_dir /dataset/data/ru/clips --filter_alphabet /dataset/data/ru/alphabet.txt /dataset/data/ru 
# echo "dateset prepared"
# cd /dataset/data/ru/clips/
# python3 -m deepspeech_training.util.check_characters -csv train.csv,dev.csv,test.csv -alpha
# echo "alphabet checked"
# nvidia-smi
cd /DeepSpeech
echo "start learning"
python3 DeepSpeech.py --train_files /dataset/data/ru/clips/train.csv --dev_files /dataset/data/ru/clips/dev.csv --test_files /dataset/data/ru/clips/test.csv --export_dir /output/result --checkpoint_dir /output/checkpoint --alphabet_config_path /dataset/data/alphabet.txt --epochs 10
