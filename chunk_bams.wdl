version 1.0


task bam_to_fasta_sampler {
  input {
    File input_bam
    Int chunk_size
    Int n_samples
  }
  command {

  }
  output {
    Array[File] output_bams = glob("*.bam")
  }
}


workflow test_bam_to_fasta_sampler {
  input {
    String input_bam
    Int chunk_size
    Int n_samples
  }
  call split_bam {
    input:
      input_bam = input_bam,
      split_length = split_length
  }
  output {
    Array[File] output_bams = split_bam.output_bams
  }
}
