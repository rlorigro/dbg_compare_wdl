version 1.0


task sample_intervals {
  input {
    String input_bam
    String output_directory
    Int chunk_size
    Int n_samples
    String? forbidden_contigs = ""
  }
  command {
    python3 /software/get_random_intervals.py -i ~{input_bam} -o ~{output_directory} -c ~{chunk_size} -n ~{n_samples} -f ~{forbidden_contigs}
  }
  output {
    File output_bed = "~{output_directory + '/intervals.bed'}"
  }
  runtime {
    docker: 'us-central1-docker.pkg.dev/broad-dsp-lrma/dbg-compare/dbg-compare:latest'
  }
}


workflow get_random_intervals {
  input {
    String input_bam
    Int chunk_size
    Int n_samples
    String? forbidden_contigs = ""
  }

  call sample_intervals {
    input:
      input_bam = input_bam,
      output_directory = "intervals",
      chunk_size = chunk_size,
      n_samples = n_samples,
      forbidden_contigs = forbidden_contigs
  }

  output {
    File output_intervals = sample_intervals.output_bed
  }
}
