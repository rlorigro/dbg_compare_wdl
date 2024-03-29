version 1.0


task split_bed_file {
  input {
    File input_bed
    Int max_concurrency
  }

  command {
    split --additional-suffix .bed -n l/~{max_concurrency} ~{input_bed} chunk_
  }

  output {
    Array[File] output_beds = glob("chunk_*.bed")
  }

  runtime {
    docker: 'ubuntu:22.04'
  }

}


task merge_samples {
  input {
    Array[String] bam_paths
    File input_bed
    Int? n_threads = 8
    Int? mem_size_gb = 16
    Int? disk_size_gb = 500
    Int? preemptible = 1
  }

  # Run python script which will use samtools to merge/fetch appropriate samples/intervals and convert to FASTAs
  command {
    python3 /software/merge_bams_by_interval.py -c ~{n_threads} --bed ~{input_bed} --bams ${sep=',' bam_paths} -o output
  }

  output {
    Array[File] output_tarballs = glob("output/*.tar.gz")
  }

  runtime {
    docker: 'us-central1-docker.pkg.dev/broad-dsp-lrma/dbg-compare/dbg-compare:latest'
    disks: "local-disk " + disk_size_gb + " SSD"
    memory: mem_size_gb + " GB"
    cpu: n_threads
    preemptible: preemptible
  }
}


workflow merge_samples_by_intervals {
  input {
    Array[String] bam_paths
    File input_bed
    Int max_concurrency
    Int n_threads_per_worker
  }

  call split_bed_file {
    input:
      input_bed = input_bed,
      max_concurrency = max_concurrency
  }

  # Now that the input BED has been split into `max_concurrency` chunks, scatter them
  scatter(x in split_bed_file.output_beds) {
      call merge_samples as scattered_merge_samples {
      input:
        bam_paths = bam_paths,
        input_bed = x,
        n_threads = n_threads_per_worker
    }
  }

  output {
    Array[File] output_tarballs = flatten(scattered_merge_samples.output_tarballs)
  }
}
