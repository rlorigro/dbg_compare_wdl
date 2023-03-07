from pysam import AlignmentFile,AlignmentHeader
import subprocess
import argparse
import io
import os


def get_header(bam_path, output_directory):
    header_path = os.path.join(output_directory, "header.sam")

    with open(header_path,'w') as f:
        result = subprocess.run(["gcloud","auth","print-access-token"], stdout=subprocess.PIPE, check=True)
        os.environ["GCS_OAUTH_TOKEN"] = result.stdout.decode("utf-8").strip().split('\n')[0]

        result = subprocess.run(["samtools", "view", "-H", bam_path], stdout=subprocess.PIPE, check=True)
        f.write(result.stdout.decode("utf-8"))

    header_only = AlignmentFile(header_path)

    for r in header_only.references:
        l = header_only.get_reference_length(r)
        print(l)

    return


def chunk_bam(chunk_size):
    pass


def main(bam_path, output_directory):
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    get_header(bam_path, output_directory)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()

    parser.add_argument(
        "-i",
        required=True,
        type=str,
        help="Input BAM to be chunked"
    )

    parser.add_argument(
        "-o",
        required=True,
        type=str,
        help="Output directory"
    )

    args = parser.parse_args()

    main(bam_path=args.i, output_directory=args.o)
