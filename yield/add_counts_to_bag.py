#!/usr/bin/python
from __future__ import absolute_import, print_function, division

import rosbag
import argparse as ap
import genpy
import re
import sys
import os
import errno
import csv
from sensor_msgs.msg import Illuminance


def get_all_files_with_ext_in_dir(directory, extension, recursive=False):
    all_files = []

    # Check if this directory exists
    if not os.path.isdir(directory):
        raise IOError('Directory not found: ', directory)

    # Check if this is a valid extension
    if not extension.startswith('.'):
        extension = '.' + extension

    # Go through this directory and find all files with this extension
    for root, dirs, files in os.walk(directory):
        files = [file for file in files if file.endswith(extension)]
        if files:
            all_files.extend([os.path.join(root, file) for file in files])
        # stop if we are not looking for files recursively
        if not recursive:
            break

    return all_files


def get_all_files_with_ext_in_dir(directory, extension, recursive=False):
    all_files = []

    # Check if this directory exists
    if not os.path.isdir(directory):
        raise IOError('Directory not found: ', directory)

    # Check if this is a valid extension
    if not extension.startswith('.'):
        extension = '.' + extension

    # Go through this directory and find all files with this extension
    for root, dirs, files in os.walk(directory):
        files = [file for file in files if file.endswith(extension)]
        if files:
            all_files.extend([os.path.join(root, file) for file in files])
        # stop if we are not looking for files recursively
        if not recursive:
            break

    return all_files


def get_all_bagfiles_in_dir(directory, recursive=False):
    return get_all_files_with_ext_in_dir(directory, '.bag', recursive)


def get_all_bagfiles_in_dir(directory, recursive=False):
    return get_all_files_with_ext_in_dir(directory, '.bag', recursive)


class BagHelper:
    def __init__(self, in_bag_path, out_dir=None, suffix="fixed"):
        # in and out should be valid full path
        self.in_bag_path = in_bag_path
        self.out_dir = out_dir

        self.bag_file = os.path.basename(self.in_bag_path)
        self.bag_name, self.bag_ext = os.path.splitext(self.bag_file)

        self.in_dir = os.path.dirname(self.in_bag_path)
        if self.out_dir is None or os.path.samefile(self.out_dir, self.in_dir):
            self.out_dir = self.in_dir

        self.out_bag_path = os.path.join(
            self.out_dir,
            self.bag_name + "_" + suffix + self.bag_ext)

    def __str__(self):
        return "input:      ${0:s}\n" \
               "output:     ${1:s}\n" \
               "output_dir: ${2:s}".format(self.in_bag_path, self.out_bag_path,
                                           self.out_dir)


def make_sure_path_exists(path):
    try:
        os.makedirs(path)
    except OSError as exception:
        print("{0:s} already exists.".format(path))
        if exception.errno != errno.EEXIST:
            raise


def process_input_args(in_args, recursive=False):
    all_inputs = []

    for in_arg in in_args:
        if os.path.isdir(in_arg):
            all_inputs.extend(get_all_bagfiles_in_dir(in_arg, recursive))
        elif os.path.isfile(in_arg):
            if in_arg.endswith('.bag'):
                all_inputs.append(in_arg)

    return all_inputs


def process_io_args(args):
    all_in_bags = process_input_args(args.input, args.recursive)

    # If output_dir is specified, make sure it exists
    if args.output_dir is not None:
        make_sure_path_exists(args.output_dir)

    # Create BagHelper for further processing
    bag_helpers = []
    for in_bag in all_in_bags:
        bag_helpers.append(BagHelper(in_bag, args.output_dir, 'counts'))

    return bag_helpers


def get_io_parser():
    parser = ap.ArgumentParser(add_help=False)
    parser.add_argument('input', nargs='+',
                        help='Input directory or bagfiles.')
    parser.add_argument('-o', '--output-dir',
                        help=('Output directory of bagfiles.'
                              'If you did not specify one, the resulting '
                              'bagfiles will put in the same folder with '
                              'a suffix, '
                              'usually _fixed).'))
    parser.add_argument('-r', '--recursive', action='store_true',
                        help=('Search recursively in input directory for '
                              'bagfiles.'))

    return parser


def read_counts_file(bag_dir, bag_name):
    counts = []

    m = re.search('([a-z]{1})([0-9]+)([a-z]{1})', bag_name)
    file_name = m.group(0)
    file_path = os.path.join(bag_dir, file_name + '.csv')

    if not os.path.exists(file_path):
        return None

    with open(file_path, 'r') as csvfile:
        csvreader = csv.reader(csvfile, delimiter=',')
        # Skip the first line
        csvreader.next()
        for row in csvreader:
            counts.append(row)

    return counts


def write_counts_to_bag(bag_helper, counts):
    with rosbag.Bag(bag_helper.in_bag_path) as in_bag:
        with rosbag.Bag(bag_helper.out_bag_path, 'w') as out_bag:
            # Write counts messages
            for sec, nsec, counts in counts:
                illuminance = Illuminance()
                illuminance.illuminance = float(counts)
                illuminance.header.frame_id = "color"
                illuminance.header.stamp = genpy.Time(int(sec), int(nsec))
                out_bag.write("counts", illuminance, illuminance.header.stamp)
            # Write original messages
            for topic, msg, t in in_bag.read_messages():
                out_bag.write(topic, msg,
                              msg.header.stamp if msg._has_header else t)


def main():
    parser = ap.ArgumentParser(description='Add fruit counts to bag files.',
                               parents=[get_io_parser()])
    args = parser.parse_args()
    all_bag_helpers = process_io_args(args)
    for bag_helper in all_bag_helpers:
        # Read corresponding csv file
        counts = read_counts_file(bag_helper.in_dir, bag_helper.bag_name)
        if counts is None:
            continue
        # Write to a new bag
        write_counts_to_bag(bag_helper, counts)


if __name__ == '__main__':
    sys.exit(main())
