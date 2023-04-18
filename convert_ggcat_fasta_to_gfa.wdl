version 1.0


task ggcat_fasta_to_gfa {
  input {
    Array[File] files
    Int? n_threads = 2
    Int? mem_size_gb = 16
    Int? disk_size_gb = 256
    Int? preemptible = 1
  }

  command {
    for x in ~{sep=' ' files}; do
        scripts/convert_ggcat_fasta_to_gfa.py -i $x
    done;
  }

  output {
    Array[File] output_gfas = glob("output/*.gfa")
  }

  runtime {
    docker: "us-central1-docker.pkg.dev/broad-dsp-lrma/dbg-compare/dbg-compare:latest"
    disks: "local-disk " + disk_size_gb + " SSD"
    memory: mem_size_gb + " GB"
    cpu: n_threads
    preemptible: preemptible
  }
}


task chunk_array {
    input {
    Array[String] array
    Int n_chunks
  }

  command {
    split --additional-suffix .txt -n l/~{n_chunks} ${write_lines(array)} chunk_
  }

  output {
    Array[File] chunked_array = glob("chunk_*.txt")
  }

  runtime {
    docker: 'ubuntu:22.04'
  }
}


workflow convert_ggcat_fastas_to_gfas {
  input {
    Array[String] tarball_paths
    Int max_concurrency = 2
    Int? n_cores_per_worker = 2
    Int? mem_size_gb = 16
    Int? disk_size_gb = 256
    Int? preemptible = 1
  }

  call chunk_array {
    input:
      array = tarball_paths,
      n_chunks = max_concurrency
  }

  # Now that the input Array has been split into `max_concurrency` chunks, scatter them
  scatter(x in chunk_array.chunked_array) {
    call ggcat_fasta_to_gfa as scattered_fasta_to_gfa {
      input:
        files = read_lines(x),
        n_threads = n_cores_per_worker,
        mem_size_gb = mem_size_gb,
        disk_size_gb = disk_size_gb,
        preemptible = preemptible
    }
  }

  output {
    Array[File] output_gfas = flatten(scattered_fasta_to_gfa.output_gfas)
  }
}
