#!/bin/bash

OUTPUT_ROOT_DIR=$HOME/birdset_benchmark_results

for DATASET in NBP PER NES UHH HSN NBP SSW SNE; do
  OUTPUT_DIR=$OUTPUT_ROOT_DIR/$DATASET
  mkdir -p $OUTPUT_DIR
  if [ $DATASET == "PER" ]; then
    N_WORKERS=1
  else
    N_WORKERS=5
  fi
  poetry run python -m birdset.eval \
    experiment=birdset_neurips24/$DATASET/LT/perch.yaml \
    'trainer=default.yaml' \
    module.network.model.tfhub_url=$HOME \
    module.network.model.tfhub_version=perch_v2 \
    'module.network.model.label_path=${paths.root_dir}/resources/perch/perch_v2_ebird_classes.csv' \
    datamodule.dataset.n_workers=$N_WORKERS \
    paths.output_dir=$OUTPUT_DIR
done

poetry run python -c "\
import pathlib; \
import pandas as pd; \
df = pd.concat([ \
    pd.read_json(p).assign( \
        dataset=p.parent.name, \
        name=lambda _df: _df.name.map({ \
            'test/T1Accuracy': 'T1-Acc', \
            'test/cmAP': 'cmAP', \
            'test/MultilabelAUROC': 'AUROC', \
        }), \
    ).dropna() \
    for p in pathlib.Path('$OUTPUT_ROOT_DIR').glob('*/finalmetrics.json') \
]).pivot(index='name', columns='dataset', values='value'); \
print('BirdSet metrics:\\n'); \
print(df[['PER', 'NES', 'UHH', 'HSN', 'NBP', 'SSW', 'SNE']].loc[['cmAP', 'AUROC', 'T1-Acc']])"
