# sbd-preprocess
SBD Dataset proprocessing code for **CASENet**

### License

The preprocessing code is released under the MIT License (refer to the LICENSE file for details).

### Introduction

The repository contains the preprocessing code of the [SBD dataset](http://home.bharathh.info/pubs/codes/SBD/download.html) for **CASENet**. CASENet is a recently proposed deep network with state of the art performance on category-aware semantic edge detection. For more information about CASENet, please refer to the [arXiv paper](https://arxiv.org/pdf/1705.09759.pdf) and the paper published in [CVPR 2017](http://openaccess.thecvf.com/content_cvpr_2017/papers/Yu_CASENet_Deep_Category-Aware_CVPR_2017_paper.pdf).

### Citation

If you find **CASENet** useful in your research, please consider to cite:

    @inproceedings{yu2017casenet,
        author = {Yu, Zhiding and Feng, Chen and Liu, Ming-Yu and Ramalingam, Srikumar},
        title = {CASENet: Deep Category-Aware Semantic Edge Detection},
        booktitle = {Proceedings of the IEEE conference on computer vision and pattern recognition},
        Year = {2017}
    }

### Usage
**Note:** In this part, we assume you are in the directory **`$SBD_PREPROCESS_ROOT/`**

1. Download the SBD dataset tarball to **`data_orig/`** and untar it.

	```Shell
	wget -O ./data_orig/bencharmk.tgz "http://www.eecs.berkeley.edu/Research/Projects/CS/vision/grouping/semantic_contours/benchmark.tgz"
	tar -xvzf ./data_orig/bencharmk.tgz -C ./data_orig/
	```
2. Run the matlab code to preprocess the data.

	```Matlab
	# In Matlab Command Window
	run code/demo_preprocess.m
	```
    This will perform data augmentation, generate .bin edge labels that could be read by CASENet, and create the corresponding file lists in **`data_aug/`**.

