import os
import json
import pandas as pd
import argparse


def read_results_from_dataset_dir(dataset_dir):
    res_filepath = None
    for filename in os.listdir(dataset_dir):
        if filename.endswith("json") and "metric" in filename:
            res_filepath = os.path.join(dataset_dir, filename)
    if res_filepath is None:
        assert False, "No results file found in dataset directory"
    
    # read json file
    with open(res_filepath, "r") as f:
        results = json.load(f)
    # return {"dataset": os.path.basename(dataset_dir), "acc": results['acc']}
    return {f"{os.path.basename(dataset_dir)}": results['acc']}


def gather_all_dataset_eval_results_from_one_ckpt_dir(ckpt_dir, save_name = None, if_write_results = False, column_names = None):
    dataset_dirs = [os.path.join(ckpt_dir, d) for d in os.listdir(ckpt_dir) if os.path.isdir(os.path.join(ckpt_dir, d))]
    key_name = os.path.basename(ckpt_dir)
    results = {}
    for d in dataset_dirs:
        print(d)
        results.update(read_results_from_dataset_dir(d))

    ret = {f"{key_name}": results}

    if if_write_results:
        if save_name is None:
            save_name = key_name
        
        convert_dict_to_csv(ret, os.path.join(ckpt_dir, save_name + ".csv"))
        return 
    
    return ret

# def reformat_from_json_to_list(res_dict, keys):
#     print(res_dict)
#     rets = []
#     for key in keys:
#         rets.append(res_dict[key])
#     print(rets)
#     return rets

# def write_data_into_csv(data, save_path):

#     df = pd.DataFrame(data)

#     output_csv = f'{save_path}.csv'

#     df.T.to_csv(output_csv, index=False, header = False, encoding='utf-8')

#     print(f"The results already are written into {output_csv}!")


def convert_dict_to_csv(data, output_csv):
    df = pd.DataFrame(data).T.reset_index()
    
    columns = ['name'] + list(data[next(iter(data))].keys())
    
    df.columns = columns

    df['average'] = df.iloc[:, 1:].mean(axis=1)

    df.to_csv(output_csv, index=False, encoding='utf-8', header=True)

    print(f"The results already are written into {output_csv}!")

def plot_results_across_dataset_and_ckpt(data, save_path):
    import matplotlib.pyplot as plt

    df = pd.DataFrame(data).T.reset_index()
    columns = ['name'] + list(data[next(iter(data))].keys())
    df.columns = columns

    df['average'] = df.iloc[:, 1:].mean(axis=1)

    # ensure the oder
    df = df.sort_values(by='name', key=lambda x: x.str.extract('(\d+)', expand=False).astype(int))

    plt.figure(figsize=(12, 8))

    for column in df.columns[1:]:
        plt.plot(df['name'], df[column], marker='o', label=column)

    # setting the figure title and label
    plt.title('Performance Metrics')
    plt.xlabel('Training tokens (B)')
    plt.ylabel('Accuracy')

    # show the legend
    plt.legend()

    plt.xticks(rotation=45)
    plt.grid(True)
    # plt.show()
    plt.savefig(save_path)

def gather_all_dataset_eval_results_from_all_ckpt_dirs(ckpt_dirs, save_name):

    all_ckpt_dirs = [os.path.join(ckpt_dirs, d) for d in os.listdir(ckpt_dirs) if os.path.isdir(os.path.join(ckpt_dirs, d))]
    example_results = gather_all_dataset_eval_results_from_one_ckpt_dir(all_ckpt_dirs[0])
    all_data_key = list(example_results[list(example_results.keys())[0]].keys())

    all_results = {}
    for ckpt_dir in all_ckpt_dirs:
        cur_ckpt_results = gather_all_dataset_eval_results_from_one_ckpt_dir(ckpt_dir)
        dict_key = os.path.basename(ckpt_dir)
        # reformatted_results = {
        #     f"{dict_key}": reformat_from_json_to_list(cur_ckpt_results[dict_key], all_data_key)
        # }
        # all_results.update(reformatted_results)
        all_results.update(cur_ckpt_results)
    print(all_results)

    if save_name == None:
        save_name = os.path.basename(ckpt_dirs)
    convert_dict_to_csv(all_results, os.path.join(ckpt_dirs, save_name + ".csv"))

    plot_results_across_dataset_and_ckpt(all_results, os.path.join(ckpt_dirs, save_name + ".pdf"))


if __name__ == "__main__":
    
    parser = argparse.ArgumentParser()
    parser.add_argument("--do_one_ckpt", action="store_true")
    parser.add_argument("--do_all_ckpts", action="store_true")
    parser.add_argument("--save_name", default=None, type=str)
    parser.add_argument("--dir_path", default="", type=str)
    args = parser.parse_args()

    COLUMN_NAMES = None

    if args.do_one_ckpt:
        gather_all_dataset_eval_results_from_one_ckpt_dir(
            args.dir_path, 
            save_name = args.save_name, 
            if_write_results = True, 
            column_names = COLUMN_NAMES
        )
    
    elif args.do_all_ckpts:
        gather_all_dataset_eval_results_from_all_ckpt_dirs(
            args.dir_path, 
            save_name = args.save_name
        )
    else:
        raise Exception("Please specify the mode!")