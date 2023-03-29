version 1.0


task profile {
  input {
    Array[File] files
    String tool_name
    Int? k = 31
    Int? n_threads = 8
    Int? mem_size_gb = 16
    Int? disk_size_gb = 500
    Int? preemptible = 1
  }

  command {
    python3 /software/profile.py \
    --tars ~{sep=',' files} \
    -g ~{tool_name} \
    -k ~{k} \
    -c ~{n_threads} \
    -o output
  }

  output {
    Array[File] output_tarballs = glob("output/*.tar.gz")
  }

  runtime {
    docker: 'us-central1-docker.pkg.dev/broad-dsp-lrma/dbg-compare/bifrost:latest'
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


workflow profile_dbg {
  input {
    Array[String] tarball_paths
    String dbg_name
    Int max_concurrency = 1
    Int? k = 31
    Int? n_cores_per_worker = 8
    Int? mem_size_gb = 16
    Int? disk_size_gb = 500
    Int? preemptible = 1
  }

  call chunk_array {
    input:
      array = tarball_paths,
      n_chunks = max_concurrency
  }

  # Now that the input Array has been split into `max_concurrency` chunks, scatter them
  scatter(x in chunk_array.chunked_array) {
    call profile as scattered_profile {
      input:
        files = read_lines(x),
        tool_name = dbg_name,
        k = k,
        n_threads = n_cores_per_worker,
        mem_size_gb = mem_size_gb,
        disk_size_gb = disk_size_gb,
        preemptible = preemptible
    }
  }

  output {
    Array[File] output_tarballs = flatten(scattered_profile.output_tarballs)
  }
}
