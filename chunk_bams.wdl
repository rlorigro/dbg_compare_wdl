version 1.0

task split_bam {
  input {
    File input_bam
    Int split_length
  }
  command {
  }
  output {
    Array[File] output_bams = glob("*.bam")
  }
}

workflow bam_splitter {
  input {
    File input_bam
    Int split_length
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
