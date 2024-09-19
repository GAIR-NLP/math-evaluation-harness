set -ex

# PROMPT_TYPE=$1
MODEL_NAME_OR_PATH=$1


# ======= Base Models =======
# PROMPT_TYPE="cot" # direct / cot / pal / tool-integrated
# MODEL_NAME_OR_PATH=${HF_MODEL_DIR}/mistral/Mistral-7B-v0.1
# MODEL_NAME_OR_PATH=${HF_MODEL_DIR}/llemma/llemma_7b
# MODEL_NAME_OR_PATH=${HF_MODEL_DIR}/internlm/internlm2-math-base-7b
# MODEL_NAME_OR_PATH=${HF_MODEL_DIR}/deepseek/deepseek-math-7b-base


# ======= SFT Models =======
# PROMPT_TYPE="deepseek-math" # self-instruct / tora / wizard_zs / deepseek-math / kpmath
# MODEL_NAME_OR_PATH=${HF_MODEL_DIR}/deepseek/deepseek-math-7b-rl
# MODEL_NAME_OR_PATH=${HF_MODEL_DIR}/deepseek/deepseek-math-7b-instruct


last_dirs=$(scripts/get_last_n_dirs.sh ${MODEL_NAME_OR_PATH} 4)

echo $last_dirs

OUTPUT_DIR="./outputs/$last_dirs"

mkdir -p "$OUTPUT_DIR"


DEFAULT_DATA_NAMES="gsm8k,minerva_math,svamp,asdiv,mawps,tabmwp,mathqa,mmlu_stem,sat_math"
DATA_NAMES=$DEFAULT_DATA_NAMES
SPLIT="test"
NUM_TEST_SAMPLE=-1

TP=1

# check the second or third parameters
if [ $# -eq 2 ]; then
    # check whether the second parameter is a number or a dataset_name
    if [[ "$2" =~ ^[0-9]+$ ]]; then
        TP="$2" # if the second parameter is a number, it is TP
    else
        DATA_NAMES="$2"  # else it is dataset_name
    fi
elif [ $# -eq 3 ]; then
    DATA_NAMES="$2"
    TP="$3"
fi



# single-gpu
# CUDA_VISIBLE_DEVICES=0 TOKENIZERS_PARALLELISM=false \
# python3 -u math_eval.py \
#     --model_name_or_path ${MODEL_NAME_OR_PATH} \
#     --output_dir ${OUTPUT_DIR} \
#     --data_names ${DATA_NAMES} \
#     --split ${SPLIT} \
#     --prompt_type ${PROMPT_TYPE} \
#     --num_test_sample ${NUM_TEST_SAMPLE} \
#     --seed 0 \
#     --temperature 0 \
#     --n_sampling 1 \
#     --top_p 1 \
#     --start 0 \
#     --end -1 \
#     --use_vllm \
#     --save_outputs \
#     # --overwrite \


# multi-gpu
python3 scripts/run_eval_multi_gpus.py \
    --model_name_or_path $MODEL_NAME_OR_PATH \
    --output_dir $OUTPUT_DIR \
    --data_names ${DATA_NAMES} \
    --prompt_type "cot" \
    --temperature 0 \
    --use_vllm \
    --save_outputs \
    --available_gpus 0,1,2,3,4,5,6,7 \
    --gpus_per_model $TP \
    --overwrite