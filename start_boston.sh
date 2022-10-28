#!/bin/bash
# Break on any error
set -e

DATASET_DIR=/mnt/data/

# Hyperparameters
GAN_EPOCHS=30
CLASSIFIER_EPOCHS=3
CF_COUNT=50
GENERATOR_MODE=open_set
RESULTS_DIR="./out_new"


mkdir -p "$RESULTS_DIR"

if [ ! -f "$RESULTS_DIR/params.json" ]; then
    echo "Create params file first using the following command:"
    echo "     python generativeopenset/create_experiment.py \\"
    echo "             --result_dir '${RESULTS_DIR}' \\"
    echo "             --dataset '/mnt/data/boston.dataset' \\"
    echo "             --hypothesis 'boston simple' \\"
    echo "             --image_size 200"
    exit -2
fi


# Command to create the params file
# python "generativeopenset/create_experiment.py" \
#         --result_dir "${RESULTS_DIR}" \
#         --dataset "/mnt/data/boston.dataset" \
#         --hypothesis "boston simple" \
#         --image_size 200



# Train the intial generative model (E+G+D) and the initial classifier (C_K)
python src/train_gan.py --epochs $GAN_EPOCHS --result_dir "$RESULTS_DIR"

# Baseline: Evaluate the standard classifier (C_k+1)
python src/evaluate_classifier.py --result_dir "$RESULTS_DIR" --mode baseline
python src/evaluate_classifier.py --result_dir "$RESULTS_DIR" --mode weibull

cp $RESULTS_DIR/checkpoints/classifier_k_epoch_00${GAN_EPOCHS}.pth \
   $RESULTS_DIR/checkpoints/classifier_kplusone_epoch_00${GAN_EPOCHS}.pth

# Generate a number of counterfactual images (in the K+2 by K+2 square grid format)
python src/generate_${GENERATOR_MODE}.py \
    --result_dir $RESULTS_DIR \
    --count $CF_COUNT

# Automatically label the rightmost column in each grid (ignore the others)
python src/auto_label.py --output_filename "$RESULTS_DIR/generated_images_${GENERATOR_MODE}.dataset"

# Train a new classifier, now using the aux_dataset containing the counterfactuals
python src/train_classifier.py --epochs $CLASSIFIER_EPOCHS --aux_dataset "$RESULTS_DIR/generated_images_${GENERATOR_MODE}.dataset"

# Evaluate the C_K+1 classifier, trained with the augmented data
python src/evaluate_classifier.py --result_dir "$RESULTS_DIR" --mode fuxin

./print_results.sh
