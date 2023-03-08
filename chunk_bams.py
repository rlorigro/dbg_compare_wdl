from pysam import AlignmentFile,AlignmentHeader
import pysam

import google.auth.transport.requests
import google.auth

from time import sleep
import subprocess
import requests
import argparse
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

            os.environ["GCS_OAUTH_TOKEN"] = self.creds.token

    def test_expiration(self):
        for i in range(15):
            print(i)
            self.update_environment()
            sleep(60*10)


def get_header(bam_path, output_directory, token):
    # There is actually a small chance that the token will expire in the time between checking and downloading...
    token.update_environment()
    header = AlignmentFile(bam_path).header

    for r in header.references:
        l = header.get_reference_length(r)
        print(l)

    return


def chunk_bam(chunk_size):
    pass


def main(bam_path, output_directory):
    if not os.path.exists(output_directory):
        os.makedirs(output_directory)

    token = GoogleToken()

    get_header(bam_path=bam_path, output_directory=output_directory, token=token)

    token.get_token()


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
