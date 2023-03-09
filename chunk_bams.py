from pysam import AlignmentFile,AlignmentHeader
import pysam

import google.auth.transport.requests
import google.auth

from time import sleep
import subprocess
import requests
import argparse
import random
import sys
import os


# Needs pip library `requests`
class GoogleToken:
    def __init__(self):
        self.creds, self.project = google.auth.default()
        self.auth_req = google.auth.transport.requests.Request()

    def get_token(self):
        if (not self.creds.valid) or self.creds.expired:
            print("Refreshing token...")
            self.creds.refresh(self.auth_req)

        return self.creds.token

    def update_environment(self):
        if (not self.creds.valid) or self.creds.expired:
            print("Updating environment token...")
            self.creds.refresh(self.auth_req)

            print(self.creds.token)

            os.environ["GCS_OAUTH_TOKEN"] = self.creds.token

    def test_expiration(self):
        for i in range(15):
            print(i)
            self.update_environment()
            sleep(60*10)


def get_remote_header(bam_path, output_directory, token):
    # There is a small chance that this will fail if the token expires between updating and downloading...
    token.update_environment()
    header = AlignmentFile(bam_path,'r').header

    return header


# def get_remote_region(bam_path, contig, start, stop, output_directory, token):
#     output_filename = "%s_%d-%d.bam" % (contig, start, stop)
#     output_path = os.path.join(output_directory,output_filename)
#
#     # There is a small chance that this will fail if the token expires between updating and downloading...
#     token.update_environment()
#     # region = pysam.view(bam_path,"-h","-F4","%s:%d-%d"%(contig,start,stop))
#
#     alignment_file = AlignmentFile(bam_path)
#     region = alignment_file.fetch(contig=contig,start=start,stop=stop)
#
#     with open(output_path, 'wb') as file:
#         for item in region:
#             print(vars(item))
#             # file.write(item)
#
#     return region


# Requires samtools installed!
def get_remote_region_as_fasta(bam_path, contig, start, stop, output_directory, token):
    region_string = "%s:%d-%d" % (contig, start, stop)
    output_filename = region_string.replace(":","_") + ".fasta"
    output_path = os.path.join(output_directory,output_filename)

    print(region_string)

    # There is a small chance that this will fail if the token expires between updating and downloading...
    token.update_environment()

    samtools_view_args = ["samtools", "view", "-b", "-h", "-F", "4", bam_path, region_string]
    samtools_fasta_args = ["samtools", "fasta", "-"]

    with open(output_path, 'w') as file:
        sys.stderr.write(" ".join(samtools_view_args)+'\n')

        p1 = subprocess.Popen(samtools_view_args, stdout=subprocess.PIPE)
        p2 = subprocess.Popen(samtools_fasta_args, stdin=p1.stdout, stdout=file)
        p2.communicate()

    return


def chunk_bam(chunk_size):
    pass


def main(bam_paths, chunk_size, n_samples, output_directory):
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    token = GoogleToken()

    header = get_remote_header(bam_path=bam_paths[0], output_directory=output_directory, token=token)

    contig_lengths = list()
    for r in header.references:
        l = int(header.get_reference_length(r))
        contig_lengths.append([r,l])

    regions = list()

    for s in range(n_samples):
        contig,length = random.choice(contig_lengths)

        start = random.randint(1,max(1,length-chunk_size+1))
        stop = min(length,start + chunk_size - 1)

        regions.append([contig,start,stop])

    for contig,start,stop in regions:
        for bam_path in bam_paths:
            get_remote_region_as_fasta(
                bam_path=bam_path,
                contig=contig,
                start=start,
                stop=stop,
                output_directory=output_directory,
                token=token,
            )


def parse_comma_separated_string(s):
    return s.strip().split(',')


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "-i",
        required=True,
        type=parse_comma_separated_string,
        help="Input BAM to be chunked"
    )

    parser.add_argument(
        "-c",
        required=True,
        type=int,
        help="Chunk size"
    )

    parser.add_argument(
        "-n",
        required=True,
        type=int,
        help="Number of samples of `chunk_size` to extract randomly"
    )

    parser.add_argument(
        "-o",
        required=True,
        type=str,
        help="Output directory"
    )

    args = parser.parse_args()

    main(bam_paths=args.i, output_directory=args.o, chunk_size=args.c, n_samples=args.n)
