version 1.0


task sample_intervals {
  input {
    String input_bam
    String output_directory
    Int chunk_size
    Int n_samples
  }
  command {
    get_random_intervals -i ~{input_bam} -o ~{output_directory} -c ~{chunk_size} -n ~{n_samples}
  }
  output {
    File output_bed = "~{output_directory + '/intervals.bed'}"
  }
}


workflow get_random_intervals {
  input {
    String input_bam
    Int chunk_size
    Int n_samples
  }
  call sample_intervals {
    input:
      input_bam = input_bam,
      output_directory = "intervals",
      chunk_size = chunk_size,
      n_samples = n_samples
  }
  output {
    File output_intervals = sample_intervals.output_bed
  }
}
